// scripts/tools/verify_levels.js
// Validador de integridade e sanidade das 20 fases canônicas

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const LEVELS_DIR = path.resolve(__dirname, '../../data/levels');

console.log('🔍 Executando testes automatizados de integridade nas 20 fases...\n');

let allPassed = true;

for (let i = 1; i <= 20; i++) {
	const filename = `level_${String(i).padStart(2, '0')}.json`;
	const filePath = path.join(LEVELS_DIR, filename);

	if (!fs.existsSync(filePath)) {
		console.error(`❌ Fase ${i}: Arquivo ${filename} NÃO encontrado!`);
		allPassed = false;
		continue;
	}

	let data;
	try {
		data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
	} catch (err) {
		console.error(`❌ Fase ${i}: Falha ao analisar JSON: ${err.message}`);
		allPassed = false;
		continue;
	}

	const { grid, spawn, terrain, objects, time_limit, level_id } = data;

	if (level_id !== i) {
		console.error(`❌ Fase ${i}: level_id divergente: ${level_id}`);
		allPassed = false;
	}

	if (!grid || typeof grid.width !== 'number' || typeof grid.height !== 'number') {
		console.error(`❌ Fase ${i}: Informações de grid inválidas!`);
		allPassed = false;
	}

	if (time_limit <= 0) {
		console.error(`❌ Fase ${i}: time_limit inválido: ${time_limit}`);
		allPassed = false;
	}

	// Mapeia células de terreno
	const terrainSet = new Set();
	for (const t of terrain) {
		terrainSet.add(`${t.gx},${t.gz}`);
	}

	// Valida spawn
	const spawnKey = `${spawn.gx},${spawn.gz}`;
	if (!terrainSet.has(spawnKey)) {
		console.error(`❌ Fase ${i}: Spawn (${spawnKey}) está fora do terreno!`);
		allPassed = false;
	}

	// Valida objetos
	const objSet = new Set();
	let plantsCount = 0;
	let rocksCount = 0;

	for (const obj of objects) {
		const key = `${obj.gx},${obj.gz}`;
		if (objSet.has(key)) {
			console.error(`❌ Fase ${i}: Célula duplicada nos objetos: ${key}`);
			allPassed = false;
		}
		objSet.add(key);

		if (!terrainSet.has(key)) {
			console.error(`❌ Fase ${i}: Objeto em (${key}) está fora do terreno da ilha!`);
			allPassed = false;
		}

		if (key === spawnKey) {
			console.error(`❌ Fase ${i}: Objeto em (${key}) sobreposto com o Spawn!`);
			allPassed = false;
		}

		if (obj.type === 'rock') {
			rocksCount++;
		} else {
			plantsCount++;
		}
	}

	if (plantsCount === 0) {
		console.error(`❌ Fase ${i}: Nenhuma planta encontrada!`);
		allPassed = false;
	}

	console.log(`✅ Fase ${String(i).padStart(2, '0')}: OK (${data.name}) — Terreno: ${terrain.length}, Plantas: ${plantsCount}, Rochas: ${rocksCount}, Tempo: ${time_limit}s`);
}

if (allPassed) {
	console.log('\n🎉 SUCESSO ABSOLUTO: Todas as 20 fases passaram nos testes de integridade!');
} else {
	console.error('\n❌ Alguns testes falharam. Verifique os relatórios acima.');
	process.exit(1);
}
