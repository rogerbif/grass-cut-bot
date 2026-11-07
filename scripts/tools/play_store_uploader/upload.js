const fs = require('fs');
const path = require('path');
const { google } = require('googleapis');

// ==============================================================================
// Script Automatizado de Upload para Google Play Console
// Projeto: Grass Cut Bot (com.bifgames.grasscutbot)
// ==============================================================================

const PACKAGE_NAME = 'com.bifgames.grasscutbot';
const DEFAULT_AAB_PATH = path.resolve(__dirname, '../../../build/release/grass_cut_bot.aab');
const DEFAULT_KEY_PATH = path.resolve(__dirname, '../../../play_service_account.json');

// Parse arguments
const args = process.argv.slice(2);
let track = 'internal'; // 'internal', 'alpha' (Closed Testing), 'beta', 'production'
let aabPath = DEFAULT_AAB_PATH;
let keyPath = DEFAULT_KEY_PATH;
let notesPt = process.env.RELEASE_NOTES_PT || null;
let notesEn = process.env.RELEASE_NOTES_EN || null;

for (const arg of args) {
    if (arg.startsWith('--track=')) {
        track = arg.split('=')[1];
    } else if (arg.startsWith('--aab=')) {
        aabPath = path.resolve(arg.split('=')[1]);
    } else if (arg.startsWith('--key=')) {
        keyPath = path.resolve(arg.split('=')[1]);
    } else if (arg.startsWith('--notes-pt=')) {
        notesPt = arg.substring('--notes-pt='.length);
    } else if (arg.startsWith('--notes-en=')) {
        notesEn = arg.substring('--notes-en='.length);
    }
}

// Release Notes padrão ou customizadas
const RELEASE_NOTES = [
    {
        language: 'pt-BR',
        text: notesPt || 'Novidades da versão:\n• Ajustes finos de física de corte e resposta de ricochete.\n• Otimizações na renderização e estabilidade mobile.\n• Melhorias nas metas e navegação do arquipélago.'
    },
    {
        language: 'en-US',
        text: notesEn || "What's new in this version:\n• Refined blade cutting physics and tactile recoil response.\n• Rendering and mobile performance optimizations.\n• Improved level goals and archipelago map navigation."
    }
];

async function main() {
    console.log('==================================================');
    console.log('>>> UPLOAD AUTOMATIZADO PARA O GOOGLE PLAY CONSOLE <<<');
    console.log(`Pacote: ${PACKAGE_NAME}`);
    console.log(`Faixa de Lançamento: ${track}`);
    console.log(`Arquivo AAB: ${aabPath}`);
    console.log(`Chave da Conta: ${keyPath}`);
    console.log('==================================================');

    if (!fs.existsSync(keyPath)) {
        console.error(`\n[ERRO] Arquivo de credenciais não encontrado em: ${keyPath}`);
        console.error('Por favor, baixe a chave JSON no Google Cloud e salve como play_service_account.json na raiz do projeto.');
        process.exit(1);
    }

    if (!fs.existsSync(aabPath)) {
        console.error(`\n[ERRO] Arquivo AAB não encontrado em: ${aabPath}`);
        console.error('Por favor, compile o AAB antes de rodar o upload.');
        process.exit(1);
    }

    const auth = new google.auth.GoogleAuth({
        keyFile: keyPath,
        scopes: ['https://www.googleapis.com/auth/androidpublisher']
    });

    const play = google.androidpublisher({
        version: 'v3',
        auth: auth
    });

    try {
        console.log('\n[1/4] Iniciando sessão de edição na Google Play API...');
        const editRes = await play.edits.insert({
            packageName: PACKAGE_NAME
        });
        const editId = editRes.data.id;
        console.log(`✔ Sessão criada com sucesso (Edit ID: ${editId})`);

        console.log(`\n[2/4] Enviando Android App Bundle (.aab) [${(fs.statSync(aabPath).size / (1024 * 1024)).toFixed(2)} MB]...`);
        const bundleRes = await play.edits.bundles.upload({
            editId: editId,
            packageName: PACKAGE_NAME,
            media: {
                mimeType: 'application/octet-stream',
                body: fs.createReadStream(aabPath)
            }
        });
        const versionCode = bundleRes.data.versionCode;
        console.log(`✔ Bundle enviado e processado com sucesso! (Version Code: ${versionCode})`);

        console.log(`\n[3/4] Configurando faixa '${track}' e notas da versão...`);
        await play.edits.tracks.update({
            editId: editId,
            packageName: PACKAGE_NAME,
            track: track,
            requestBody: {
                track: track,
                releases: [
                    {
                        versionCodes: [String(versionCode)],
                        status: 'completed',
                        releaseNotes: RELEASE_NOTES
                    }
                ]
            }
        });
        console.log(`✔ Faixa '${track}' configurada com a versão ${versionCode}`);

        console.log('\n[4/4] Confirmando e publicando as alterações (Commit)...');
        await play.edits.commit({
            editId: editId,
            packageName: PACKAGE_NAME
        });

        console.log('==================================================');
        console.log('>>> [SUCESSO] VERSÃO PUBLICADA COM SUCESSO NO GOOGLE PLAY! <<<');
        console.log(`Versão: ${versionCode}`);
        console.log(`Faixa: ${track}`);
        console.log('==================================================');
    } catch (err) {
        console.error('\n[FALHA] Erro ao enviar pacote para o Google Play Console:');
        if (err.response && err.response.data && err.response.data.error) {
            console.error('Mensagem da API:', JSON.stringify(err.response.data.error, null, 2));
        } else {
            console.error(err.message || err);
        }
        process.exit(1);
    }
}

main();
