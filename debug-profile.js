const { createClient } = require('@supabase/supabase-js');

// Direct environment values for debugging
const url = 'https://owxlyrymdggalfktgzmo.supabase.co';
const key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im93eGx5cnltZGdnYWxma3Rnem1vIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzY4NDEzNTIsImV4cCI6MjA1MjQxNzM1Mn0.vgHb2B4xOlCq38gAv5Kxjz8oDMKqhQV1V0PllvjOZNA';

const supabase = createClient(url, key);

async function checkUser() {
  try {
    console.log('🔍 Checking user profile for: 550ce2c2-2d18-4a75-8ece-0c2c8f4dadad');
    
    const result = await supabase.rpc('pos_mini_modular3_get_user_profile_safe', {
      p_user_id: '550ce2c2-2d18-4a75-8ece-0c2c8f4dadad'
    });
    
    console.log('\n📊 RPC Result:');
    console.log(JSON.stringify(result, null, 2));
    
    if (result.data) {
      console.log('\n✨ Parsed Data:');
      console.log('Profile exists:', result.data.profile_exists);
      console.log('Profile:', result.data.profile);
      console.log('Business:', result.data.business);
    }
    
  } catch (error) {
    console.error('❌ Error:', error);
  }
}

checkUser();
