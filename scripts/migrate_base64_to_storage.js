/**
 * SCRIPT DE MIGRATION BASE64 -> SUPABASE STORAGE
 * 
 * Ce script :
 * 1. Lit toutes les lignes de la table `products` contenant des chaînes Base64 (catégorie '__PAGE_PHOTOS__' et colonnes 'image_path').
 * 2. Décode chaque image Base64.
 * 3. L'uploade dans le bucket public 'product-images' de Supabase Storage avec cache CDN (1 an).
 * 4. Remplace la longue chaîne Base64 par la courte URL publique (https://...jpg).
 * 
 * UTILISATION :
 *   node scripts/migrate_base64_to_storage.js <SUPABASE_SERVICE_ROLE_KEY>
 */

const { createClient } = require('@supabase/supabase-js');

const SUPABASE_URL = 'https://kntybigswxfmitrumskw.supabase.co';
const SERVICE_ROLE_KEY = process.argv[2] || process.env.SUPABASE_SERVICE_ROLE_KEY;

if (!SERVICE_ROLE_KEY) {
  console.error('\n❌ ERREUR : La clé SUPABASE_SERVICE_ROLE_KEY est requise.');
  console.error('Usage : node scripts/migrate_base64_to_storage.js <VOTRE_SERVICE_ROLE_KEY>\n');
  console.error('Vous pouvez trouver la Service Role Key dans votre Dashboard Supabase :');
  console.error('Project Settings > API > Project API keys > service_role (secret)\n');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY, {
  auth: { persistSession: false }
});

const BUCKET_NAME = 'product-images';

async function uploadBase64ToStorage(base64Data, filenamePrefix) {
  try {
    const commaIndex = base64Data.indexOf(',');
    const header = commaIndex !== -1 ? base64Data.substring(0, commaIndex) : '';
    const rawBase64 = commaIndex !== -1 ? base64Data.substring(commaIndex + 1) : base64Data;

    let mimeType = 'image/jpeg';
    let ext = 'jpg';
    if (header.includes('image/png')) {
      mimeType = 'image/png';
      ext = 'png';
    } else if (header.includes('image/webp')) {
      mimeType = 'image/webp';
      ext = 'webp';
    }

    const buffer = Buffer.from(rawBase64, 'base64');
    const fileName = `photos/${filenamePrefix}_${Date.now()}_${buffer.length}.${ext}`;

    const { error: uploadError } = await supabase.storage
      .from(BUCKET_NAME)
      .upload(fileName, buffer, {
        contentType: mimeType,
        cacheControl: '31536000',
        upsert: true
      });

    if (uploadError) {
      console.error(`  ⚠️ Erreur upload storage (${fileName}):`, uploadError.message);
      return null;
    }

    const { data: publicUrlData } = supabase.storage
      .from(BUCKET_NAME)
      .getPublicUrl(fileName);

    return publicUrlData.publicUrl;
  } catch (err) {
    console.error('  ⚠️ Exception conversion base64:', err.message);
    return null;
  }
}

async function migratePagePhotos() {
  console.log('\n--- 1. Analyse des photos de pages (__PAGE_PHOTOS__) ---');

  const { data: rows, error } = await supabase
    .from('products')
    .select('id, name, description')
    .eq('category_name', '__PAGE_PHOTOS__');

  if (error) {
    console.error('❌ Erreur lecture __PAGE_PHOTOS__:', error.message);
    return;
  }

  console.log(`Trouvé ${rows.length} lignes de configuration de page.`);

  for (const row of rows) {
    if (!row.description) continue;
    let config;
    try {
      config = JSON.parse(row.description);
    } catch (_) {
      continue;
    }

    let modified = false;
    const photoKeys = [
      'corner_photo',
      'large_bottom_photo',
      'second_bottom_photo',
      'first_alternating_photo',
      'second_alternating_photo'
    ];

    for (const key of photoKeys) {
      const val = config[key];
      if (val && typeof val === 'string' && val.startsWith('data:image')) {
        console.log(`Migration de ${row.name} -> ${key} (${(val.length / 1024).toFixed(1)} Ko en Base64)...`);
        const publicUrl = await uploadBase64ToStorage(val, `${row.name}_${key}`);
        if (publicUrl) {
          config[key] = publicUrl;
          modified = true;
          console.log(`  ✅ Remplacé par URL : ${publicUrl}`);
        }
      }
    }

    if (modified) {
      const updatedDescription = JSON.stringify(config);
      const { error: updateError } = await supabase
        .from('products')
        .update({
          description: updatedDescription,
          updated_at: new Date().toISOString()
        })
        .eq('id', row.id);

      if (updateError) {
        console.error(`  ❌ Erreur mise à jour row ${row.id}:`, updateError.message);
      } else {
        console.log(`  🎉 Ligne ${row.name} (id: ${row.id}) mise à jour dans PostgreSQL !`);
      }
    } else {
      console.log(`Ligne ${row.name} : aucune image Base64 restante.`);
    }
  }
}

async function migrateProductsImages() {
  console.log('\n--- 2. Analyse des images de produits individuels (image_path) ---');

  const { data: products, error } = await supabase
    .from('products')
    .select('id, name, image_path')
    .neq('category_name', '__PAGE_PHOTOS__')
    .like('image_path', 'data:image%');

  if (error) {
    console.error('❌ Erreur lecture produits:', error.message);
    return;
  }

  console.log(`Trouvé ${products ? products.length : 0} produits avec image en Base64.`);

  if (products && products.length > 0) {
    for (const prod of products) {
      console.log(`Migration produit "${prod.name}" (id: ${prod.id})...`);
      const publicUrl = await uploadBase64ToStorage(prod.image_path, `prod_${prod.id}`);
      if (publicUrl) {
        await supabase
          .from('products')
          .update({
            image_path: publicUrl,
            updated_at: new Date().toISOString()
          })
          .eq('id', prod.id);
        console.log(`  ✅ Produit "${prod.name}" mis à jour avec URL.`);
      }
    }
  }
}

async function run() {
  console.log('🚀 Début de la migration Supabase Base64 -> Storage');
  await migratePagePhotos();
  await migrateProductsImages();
  console.log('\n======================================================');
  console.log('✨ MIGRATION TERMINÉE AVEC SUCCÈS !');
  console.log('Pensez maintenant à exécuter dans le SQL Editor de Supabase :');
  console.log('  VACUUM FULL products;');
  console.log('Cela libérera immédiatement les ~44 Mo d\'espace disque dans PostgreSQL.');
  console.log('======================================================\n');
}

run().catch(console.error);
