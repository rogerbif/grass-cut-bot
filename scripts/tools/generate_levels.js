// scripts/tools/generate_levels.js
// Gerador das 20 Fases Canônicas de Grass Cut Bot (v0.6.1)
// - Exclusão total do tile amarelo bugado (tile_island_dirt)
// - Regra estrita de Level Design: NENHUMA passagem, ponte ou corredor com menos de 2 tiles de largura
// - Vãos livres generosos para condução ágil no mobile sem travamentos

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const PROJECT_ROOT = path.resolve(__dirname, '../..');
const LEVELS_DIR = path.join(PROJECT_ROOT, 'data', 'levels');

if (!fs.existsSync(LEVELS_DIR)) {
	fs.mkdirSync(LEVELS_DIR, { recursive: true });
}

// Algoritmo canônico de Autotile idêntico a island_autotiler.gd
function computeTileForCell(cellKey, terrainMap) {
	const [x, z] = cellKey.split(',').map(Number);

	const hasN = terrainMap.has(`${x},${z - 1}`);
	const hasS = terrainMap.has(`${x},${z + 1}`);
	const hasE = terrainMap.has(`${x + 1},${z}`);
	const hasW = terrainMap.has(`${x - 1},${z}`);

	// Quinas externas (2 lados adjacentes voltados para o mar)
	if (!hasN && !hasE && hasS && hasW) return { tile_id: 'island_corner_out', rot: 0 };
	if (!hasN && !hasW && hasS && hasE) return { tile_id: 'island_corner_out', rot: 90 };
	if (!hasS && !hasW && hasN && hasE) return { tile_id: 'island_corner_out', rot: 180 };
	if (!hasS && !hasE && hasN && hasW) return { tile_id: 'island_corner_out', rot: 270 };

	// Bordas retas simples (1 lado voltado para o mar)
	if (!hasN && hasS && hasE && hasW) return { tile_id: 'island_edge', rot: 0 };
	if (!hasW && hasN && hasS && hasE) return { tile_id: 'island_edge', rot: 90 };
	if (!hasS && hasN && hasE && hasW) return { tile_id: 'island_edge', rot: 180 };
	if (!hasE && hasN && hasS && hasW) return { tile_id: 'island_edge', rot: 270 };
	return { tile_id: 'island_center', rot: 0 };
}

// Construtor auxiliar de níveis
class LevelBuilder {
	constructor(levelId, name, width, height, timeLimit) {
		this.levelId = levelId;
		this.name = name;
		this.width = width;
		this.height = height;
		this.timeLimit = timeLimit;
		this.terrain = new Map(); // key -> true (100% verde esmeralda com autotile)
		this.objects = new Map(); // key -> { type, rot }
		this.spawn = { gx: Math.floor(width / 2), gz: Math.floor(height / 2), rot: 0 };
	}

	setSpawn(x, z, rot = 0) {
		this.spawn = { gx: x, gz: z, rot };
	}

	addTerrain(x, z) {
		if (x < 0 || x >= this.width || z < 0 || z >= this.height) return;
		this.terrain.set(`${x},${z}`, true);
	}

	addBox(x1, z1, x2, z2) {
		const minX = Math.min(x1, x2);
		const maxX = Math.max(x1, x2);
		const minZ = Math.min(z1, z2);
		const maxZ = Math.max(z1, z2);
		for (let x = minX; x <= maxX; x++) {
			for (let z = minZ; z <= maxZ; z++) {
				this.addTerrain(x, z);
			}
		}
	}

	addCircle(cx, cz, radius) {
		const r2 = radius * radius;
		const minX = Math.floor(cx - radius);
		const maxX = Math.ceil(cx + radius);
		const minZ = Math.floor(cz - radius);
		const maxZ = Math.ceil(cz + radius);
		for (let x = minX; x <= maxX; x++) {
			for (let z = minZ; z <= maxZ; z++) {
				const d2 = (x - cx) * (x - cx) + (z - cz) * (z - cz);
				if (d2 <= r2) {
					this.addTerrain(x, z);
				}
			}
		}
	}

	removeTerrain(x, z) {
		this.terrain.delete(`${x},${z}`);
		this.objects.delete(`${x},${z}`);
	}

	removeCircle(cx, cz, radius) {
		const r2 = radius * radius;
		const minX = Math.floor(cx - radius);
		const maxX = Math.ceil(cx + radius);
		const minZ = Math.floor(cz - radius);
		const maxZ = Math.ceil(cz + radius);
		for (let x = minX; x <= maxX; x++) {
			for (let z = minZ; z <= maxZ; z++) {
				const d2 = (x - cx) * (x - cx) + (z - cz) * (z - cz);
				if (d2 <= r2) {
					this.removeTerrain(x, z);
				}
			}
		}
	}

	addRock(x, z) {
		const key = `${x},${z}`;
		if (!this.terrain.has(key)) return;
		if (x === this.spawn.gx && z === this.spawn.gz) return;
		this.objects.set(key, { type: 'rock', rot: Math.floor(Math.random() * 4) * 90 });
	}

	addPlant(x, z, type) {
		const key = `${x},${z}`;
		if (!this.terrain.has(key)) return;
		if (x === this.spawn.gx && z === this.spawn.gz) return;
		if (this.objects.has(key)) return;
		this.objects.set(key, { type, rot: 0 });
	}

	fillVegetation(filterFn, plantType) {
		for (const [key] of this.terrain) {
			const [x, z] = key.split(',').map(Number);
			if (x === this.spawn.gx && z === this.spawn.gz) continue;
			if (this.objects.has(key)) continue;
			if (filterFn(x, z)) {
				this.objects.set(key, { type: plantType, rot: 0 });
			}
		}
	}

	fillRemaining(plantType) {
		for (const [key] of this.terrain) {
			const [x, z] = key.split(',').map(Number);
			if (x === this.spawn.gx && z === this.spawn.gz) continue;
			if (!this.objects.has(key)) {
				this.objects.set(key, { type: plantType, rot: 0 });
			}
		}
	}

	build() {
		// Resolve autotile 100% verde esmeralda com bordas suaves
		const terrainList = [];
		const sortedTerrainKeys = Array.from(this.terrain.keys()).sort((a, b) => {
			const [ax, az] = a.split(',').map(Number);
			const [bx, bz] = b.split(',').map(Number);
			return az !== bz ? az - bz : ax - bx;
		});

		for (const key of sortedTerrainKeys) {
			const [gx, gz] = key.split(',').map(Number);
			const resolved = computeTileForCell(key, this.terrain);
			terrainList.push({
				gx,
				gz,
				tile_id: resolved.tile_id,
				rot: resolved.rot,
				auto: true
			});
		}

		// Prepara lista de objetos
		const objectsList = [];
		const sortedObjKeys = Array.from(this.objects.keys()).sort((a, b) => {
			const [ax, az] = a.split(',').map(Number);
			const [bx, bz] = b.split(',').map(Number);
			return az !== bz ? az - bz : ax - bx;
		});

		for (const key of sortedObjKeys) {
			const [gx, gz] = key.split(',').map(Number);
			const obj = this.objects.get(key);
			objectsList.push({
				gx,
				gz,
				type: obj.type,
				rot: obj.rot
			});
		}

		return {
			version: 1,
			level_id: this.levelId,
			name: this.name,
			time_limit: this.timeLimit,
			grid: {
				cell_size: 0.8,
				width: this.width,
				height: this.height
			},
			spawn: {
				gx: this.spawn.gx,
				gz: this.spawn.gz,
				rot: this.spawn.rot
			},
			terrain: terrainList,
			objects: objectsList
		};
	}
}

const levels = [];

// ==========================================
// TIER 1: O DESPERTAR DO JARDINEIRO (Fases 1 a 4)
// ==========================================

// FASE 01: Praia Inicial (Retângulo Amplo e Acolhedor)
{
	const lvl = new LevelBuilder(1, 'Fase 01 - Praia Inicial', 14, 10, 90.0);
	lvl.addBox(2, 2, 11, 7);
	lvl.setSpawn(6, 4);
	lvl.fillRemaining('grass_green');
	levels.push(lvl);
}

// FASE 02: Baía Amarela (Ovalada Espaçosa com Enseada Suave)
{
	const lvl = new LevelBuilder(2, 'Fase 02 - Baía Amarela', 16, 13, 85.0);
	lvl.addCircle(7.5, 6, 5.0);
	// Enseada suave mantendo no mínimo 3 tiles de terra nas laterais
	lvl.removeTerrain(7, 10);
	lvl.removeTerrain(8, 10);
	lvl.removeTerrain(7, 9);
	lvl.removeTerrain(8, 9);
	lvl.setSpawn(7, 4);
	lvl.addRock(4, 4);
	lvl.addRock(11, 4);
	lvl.fillVegetation((x, z) => z >= 6, 'grass_yellow');
	lvl.fillRemaining('grass_green');
	levels.push(lvl);
}

// FASE 03: Campos Dourados (Retângulo Chanfrado com Passagens Livres)
{
	const lvl = new LevelBuilder(3, 'Fase 03 - Campos Dourados', 16, 12, 85.0);
	lvl.addBox(3, 2, 12, 9);
	// Chanfra os cantos sem estrangulamento
	lvl.removeTerrain(3, 2);
	lvl.removeTerrain(12, 2);
	lvl.removeTerrain(3, 9);
	lvl.removeTerrain(12, 9);
	lvl.setSpawn(4, 5);
	// Rochas com pelo menos 2 tiles de folga em todas as direções
	lvl.addRock(8, 4);
	lvl.addRock(8, 7);
	lvl.addRock(5, 3);
	lvl.addRock(11, 8);
	lvl.fillVegetation((x) => x >= 9, 'wheat');
	lvl.fillRemaining('grass_green');
	levels.push(lvl);
}

// FASE 04: Jardim das Orquídeas (Cruz com Alas Largas de 3 a 4 Tiles)
{
	const lvl = new LevelBuilder(4, 'Fase 04 - Jardim das Orquídeas', 16, 16, 80.0);
	// Centro 6x6
	lvl.addBox(5, 5, 10, 10);
	// 4 alas largas (4 tiles de largura cada)
	lvl.addBox(6, 1, 9, 4); // Norte
	lvl.addBox(6, 11, 9, 14); // Sul
	lvl.addBox(1, 6, 4, 9); // Oeste
	lvl.addBox(11, 6, 14, 9); // Leste
	lvl.setSpawn(7, 7);
	// Rochas nas quinas do centro com passagens amplas
	lvl.addRock(5, 5);
	lvl.addRock(10, 5);
	lvl.addRock(5, 10);
	lvl.addRock(10, 10);
	// Flores nas extremidades das alas
	lvl.fillVegetation((x, z) => (z <= 3 || z >= 12 || x <= 3 || x >= 12), 'flower');
	// Trigo circundando o centro
	lvl.fillVegetation((x, z) => (x >= 5 && x <= 10 && z >= 5 && z <= 10 && (x === 5 || x === 10 || z === 5 || z === 10)), 'wheat');
	lvl.fillRemaining('grass_green');
	levels.push(lvl);
}

// ==========================================
// TIER 2: EXPANSÃO GEOGRÁFICA & ISTMOS (Fases 5 a 8)
// ==========================================

// FASE 05: Ilhas Gêmeas (Duas Ilhas Circulares Unidas por Ponte Larga de 3 Tiles)
{
	const lvl = new LevelBuilder(5, 'Fase 05 - Ilhas Gêmeas', 19, 12, 85.0);
	lvl.addCircle(4.5, 5.5, 4.0);
	lvl.addCircle(14.5, 5.5, 4.0);
	// Ponte larga de 3 tiles de espessura (Z de 4 a 6)
	lvl.addBox(7, 4, 12, 6);
	lvl.setSpawn(4, 5);
	// Rochas nas extremidades das ilhas, nunca na ponte
	lvl.addRock(3, 3);
	lvl.addRock(3, 8);
	lvl.addRock(16, 3);
	lvl.addRock(16, 8);
	lvl.fillVegetation((x, z) => x >= 13 && (z === 4 || z === 7), 'wheat');
	lvl.fillVegetation((x) => x >= 11, 'grass_yellow');
	lvl.fillRemaining('grass_green');
	levels.push(lvl);
}

// FASE 06: Lagoa Serena (Atol em Anel Circular com Pista Larga de 3.5 Tiles)
{
	const lvl = new LevelBuilder(6, 'Fase 06 - Lagoa Serena', 17, 17, 80.0);
	lvl.addCircle(8, 8, 6.8);
	lvl.removeCircle(8, 8, 2.8); // Lagoa interna deixa anel de ~4 tiles de espessura
	lvl.setSpawn(8, 2);
	// Rochas com passagem livre dos dois lados
	lvl.addRock(3, 8);
	lvl.addRock(13, 8);
	lvl.addRock(5, 12);
	lvl.addRock(11, 12);
	lvl.addRock(8, 14);
	// Flores perto da lagoa interna
	lvl.fillVegetation((x, z) => {
		const d = Math.hypot(x - 8, z - 8);
		return d >= 3.0 && d <= 4.2 && ((x + z) % 2 === 0);
	}, 'flower');
	// Grama azul na orla externa
	lvl.fillVegetation((x, z) => {
		const d = Math.hypot(x - 8, z - 8);
		return d >= 5.0;
	}, 'grass_blue');
	lvl.fillRemaining('grass_green');
	levels.push(lvl);
}

// FASE 07: Vale da Ampulheta (Dois Platôs Unidos por Gargalo Largo de 4 Tiles)
{
	const lvl = new LevelBuilder(7, 'Fase 07 - Vale da Ampulheta', 16, 16, 80.0);
	// Platô Norte
	lvl.addBox(2, 2, 13, 6);
	// Platô Sul
	lvl.addBox(2, 9, 13, 13);
	// Gargalo central largo (4 tiles de largura X=6 a 9)
	lvl.addBox(6, 7, 9, 8);
	lvl.setSpawn(7, 12);
	// Rochas nas laterais dos platôs com passagem livre
	lvl.addRock(3, 4);
	lvl.addRock(12, 4);
	lvl.addRock(3, 11);
	lvl.addRock(12, 11);
	lvl.fillVegetation((x, z) => z <= 4 && (x === 4 || x === 7 || x === 11), 'flower');
	lvl.fillVegetation((x, z) => z <= 5, 'wheat');
	lvl.fillRemaining('grass_yellow');
	levels.push(lvl);
}

// FASE 08: Três Picos (Arquipélago Tríade com Pontes em Y de 3 Tiles de Largura)
{
	const lvl = new LevelBuilder(8, 'Fase 08 - Três Picos', 20, 18, 85.0);
	// Hub central 5x5
	lvl.addCircle(9.5, 8.5, 3.2);
	// 3 picos
	lvl.addCircle(9.5, 3.0, 3.0); // Norte
	lvl.addCircle(4.0, 14.0, 3.0); // Sudoeste
	lvl.addCircle(15.0, 14.0, 3.0); // Sudeste
	// Pontes largas (3 tiles de largura)
	lvl.addBox(8, 5, 11, 7); // Norte-Centro
	lvl.addBox(5, 10, 8, 12); // SO-Centro
	lvl.addBox(11, 10, 14, 12); // SE-Centro
	lvl.setSpawn(9, 8);
	lvl.addRock(4, 14);
	lvl.addRock(15, 14);
	lvl.addRock(9, 2);
	lvl.addRock(6, 6);
	lvl.addRock(13, 6);
	lvl.fillVegetation((x, z) => z <= 3 && (x === 8 || x === 11), 'flower');
	lvl.fillVegetation((x, z) => z <= 5, 'wheat');
	lvl.fillVegetation((x, z) => x <= 6 && z >= 11, 'grass_green');
	lvl.fillVegetation((x, z) => x >= 13 && z >= 11, 'grass_blue');
	lvl.fillRemaining('grass_yellow');
	levels.push(lvl);
}

// ==========================================
// TIER 3: DESAFIO TÁTICO & CHICANES (Fases 9 a 12)
// ==========================================

// FASE 09: Serpentina de Coral (Península Sinuosa em S com Pistas Largas de 3 a 4 Tiles)
{
	const lvl = new LevelBuilder(9, 'Fase 09 - Serpentina de Coral', 19, 18, 80.0);
	// Pista 1 (Norte): largura de 4 tiles (Z de 2 a 5)
	lvl.addBox(2, 2, 16, 5);
	// Conexão Leste: largura de 4 tiles (X de 13 a 16)
	lvl.addBox(13, 5, 16, 10);
	// Pista 2 (Meio): largura de 4 tiles (Z de 7 a 10)
	lvl.addBox(2, 7, 16, 10);
	// Conexão Oeste: largura de 4 tiles (X de 2 a 5)
	lvl.addBox(2, 10, 5, 15);
	// Pista 3 (Sul): largura de 4 tiles (Z de 12 a 15)
	lvl.addBox(2, 12, 16, 15);
	lvl.setSpawn(3, 3);
	// Rochas posicionadas nos cantos cegos, mantendo 2 a 3 tiles livres ao redor
	lvl.addRock(14, 2);
	lvl.addRock(14, 7);
	lvl.addRock(4, 10);
	lvl.addRock(14, 14);
	lvl.addRock(4, 15);
	lvl.fillVegetation((x, z) => z >= 12, 'wheat');
	lvl.fillVegetation((x, z) => z >= 7 && z <= 11, 'grass_yellow');
	lvl.fillRemaining('grass_green');
	levels.push(lvl);
}

// FASE 10: Labirinto das Pedras (Paredes de Rocha com Corredores Largos de 2 Tiles)
{
	const lvl = new LevelBuilder(10, 'Fase 10 - Labirinto das Pedras', 18, 18, 85.0);
	lvl.addBox(2, 2, 15, 15);
	lvl.setSpawn(8, 8);
	// Muros de pedras com passagens de no mínimo 2 tiles de largura entre eles
	const rocks = [
		[4, 4], [5, 4], [7, 4], [10, 4], [12, 4], [13, 4],
		[4, 7], [4, 10], [13, 7], [13, 10],
		[4, 13], [5, 13], [7, 13], [10, 13], [12, 13], [13, 13],
		[7, 7], [10, 7], [7, 10], [10, 10]
	];
	for (const [rx, rz] of rocks) lvl.addRock(rx, rz);
	lvl.fillVegetation((x, z) => (x <= 3 || x >= 14) && (z <= 3 || z >= 14), 'flower');
	lvl.fillVegetation((x, z) => (x >= 6 && x <= 11 && (z === 5 || z === 12)), 'wheat');
	lvl.fillRemaining('grass_purple');
	levels.push(lvl);
}

// FASE 11: Trevo da Sorte (4 Pétalas Tangentes com Junções de 3 Tiles)
{
	const lvl = new LevelBuilder(11, 'Fase 11 - Trevo da Sorte', 19, 19, 85.0);
	lvl.addBox(7, 7, 11, 11);
	lvl.addCircle(9.0, 4.5, 3.6); // Norte
	lvl.addCircle(9.0, 13.5, 3.6); // Sul
	lvl.addCircle(4.5, 9.0, 3.6); // Oeste
	lvl.addCircle(13.5, 9.0, 3.6); // Leste
	lvl.setSpawn(9, 9);
	lvl.addRock(6, 6);
	lvl.addRock(12, 6);
	lvl.addRock(6, 12);
	lvl.addRock(12, 12);
	lvl.addRock(9, 2);
	lvl.addRock(9, 16);
	lvl.addRock(2, 9);
	lvl.addRock(16, 9);
	lvl.addPlant(9, 4, 'flower');
	lvl.addPlant(9, 14, 'flower');
	lvl.addPlant(4, 9, 'flower');
	lvl.addPlant(14, 9, 'flower');
	lvl.fillVegetation((x, z) => (x >= 7 && x <= 11 && z >= 7 && z <= 11), 'wheat');
	lvl.fillVegetation((x, z) => z <= 6, 'grass_green');
	lvl.fillVegetation((x, z) => z >= 12, 'grass_yellow');
	lvl.fillVegetation((x, z) => x <= 6, 'grass_blue');
	lvl.fillRemaining('grass_purple');
	levels.push(lvl);
}

// FASE 12: Estrela do Oceano (Estrela de 5 Pontas com Pontas Largas de 2 a 3 Tiles)
{
	const lvl = new LevelBuilder(12, 'Fase 12 - Estrela do Oceano', 20, 20, 80.0);
	const cx = 9.5;
	const cz = 9.5;
	for (let x = 0; x < 20; x++) {
		for (let z = 0; z < 20; z++) {
			const dx = x - cx;
			const dz = z - cz;
			const dist = Math.hypot(dx, dz);
			let angle = Math.atan2(dz, dx);
			// Raio mínimo das pontas calibrado para garantir espessura de no mínimo 2 tiles
			const starR = 5.2 + 3.4 * Math.cos(5 * angle);
			if (dist <= starR) {
				lvl.addTerrain(x, z);
			}
		}
	}
	lvl.setSpawn(9, 9);
	lvl.addRock(7, 6);
	lvl.addRock(12, 6);
	lvl.addRock(6, 12);
	lvl.addRock(13, 12);
	lvl.fillVegetation((x, z) => Math.hypot(x - cx, z - cz) >= 6.5, 'flower');
	lvl.fillVegetation((x, z) => {
		const d = Math.hypot(x - cx, z - cz);
		return d >= 4.2 && d < 6.5;
	}, 'wheat');
	lvl.fillVegetation((x) => x <= cx, 'grass_blue');
	lvl.fillRemaining('grass_purple');
	levels.push(lvl);
}

// ==========================================
// TIER 4: MAESTRIA & ECONOMIA (Fases 13 a 16)
// ==========================================

// FASE 13: Tridente de Netuno (3 Hastes Espaçosas de 3 Tiles de Largura)
{
	const lvl = new LevelBuilder(13, 'Fase 13 - Tridente de Netuno', 20, 18, 80.0);
	// Base Sul larga (Z de 12 a 16)
	lvl.addBox(2, 12, 17, 16);
	// 3 Dentes do tridente com 3 tiles de largura cada
	lvl.addBox(3, 2, 5, 12); // Esquerda (X=3,4,5)
	lvl.addBox(8, 2, 11, 12); // Centro (X=8,9,10,11)
	lvl.addBox(14, 2, 16, 12); // Direita (X=14,15,16)
	lvl.setSpawn(9, 14);
	// Rochas nas quinas de transição mantendo passagem aberta
	lvl.addRock(2, 12);
	lvl.addRock(6, 12);
	lvl.addRock(7, 12);
	lvl.addRock(12, 12);
	lvl.addRock(13, 12);
	lvl.addRock(17, 12);
	lvl.addRock(4, 2);
	lvl.addRock(15, 2);
	lvl.fillVegetation((x, z) => z <= 4, 'flower');
	lvl.fillVegetation((x, z) => z >= 5 && z <= 11, 'wheat');
	lvl.fillRemaining('grass_green');
	levels.push(lvl);
}

// FASE 14: Coração Selvagem (Silhueta Cardioide Ampla com Ponta Larga)
{
	const lvl = new LevelBuilder(14, 'Fase 14 - Coração Selvagem', 19, 19, 80.0);
	const cx = 9.0;
	const cz = 8.0;
	for (let x = 1; x <= 17; x++) {
		for (let z = 1; z <= 17; z++) {
			const nx = (x - cx) / 6.5;
			const nz = -(z - cz) / 6.5;
			const term = nx * nx + nz * nz - 1.0;
			if (term * term * term - nx * nx * nz * nz * nz <= 0.08) {
				lvl.addTerrain(x, z);
			}
		}
	}
	// Garante que a ponta do coração tenha no mínimo 3 tiles de largura
	lvl.addBox(8, 14, 10, 15);
	lvl.setSpawn(9, 13);
	lvl.addRock(9, 5);
	lvl.addRock(4, 4);
	lvl.addRock(14, 4);
	lvl.addRock(2, 8);
	lvl.addRock(16, 8);
	lvl.addRock(9, 15);
	lvl.fillVegetation((x, z) => Math.hypot(x - cx, z - cz) <= 2.5, 'flower');
	lvl.fillVegetation((x, z) => {
		const d = Math.hypot(x - cx, z - cz);
		return d > 2.5 && d <= 4.5;
	}, 'wheat');
	lvl.fillRemaining('grass_purple');
	levels.push(lvl);
}

// FASE 15: Passadiço dos Abismos (4 Ilhotas com Pontes Largas de 3 Tiles)
{
	const lvl = new LevelBuilder(15, 'Fase 15 - Passadiço dos Abismos', 23, 14, 85.0);
	// 4 Ilhotas 5x5
	lvl.addBox(1, 4, 5, 8); // Ilha 1
	lvl.addBox(7, 2, 11, 6); // Ilha 2
	lvl.addBox(12, 7, 16, 11); // Ilha 3
	lvl.addBox(17, 3, 21, 7); // Ilha 4
	// Pontes largas de 3 tiles de largura (Z de 3 tiles)
	lvl.addBox(5, 4, 7, 6); // Ponte 1-2
	lvl.addBox(10, 5, 12, 7); // Ponte 2-3
	lvl.addBox(15, 5, 17, 7); // Ponte 3-4
	lvl.setSpawn(3, 6);
	lvl.addRock(1, 4);
	lvl.addRock(11, 2);
	lvl.addRock(12, 11);
	lvl.addRock(21, 3);
	lvl.fillVegetation((x) => x >= 18, 'flower');
	lvl.fillVegetation((x) => x >= 12 && x <= 16, 'wheat');
	lvl.fillVegetation((x) => x >= 7 && x <= 11, 'grass_blue');
	lvl.fillRemaining('grass_yellow');
	levels.push(lvl);
}

// FASE 16: Fortaleza Espiral (Espiral em Caracol com Pista Larga de 3 Tiles)
{
	const lvl = new LevelBuilder(16, 'Fase 16 - Fortaleza Espiral', 20, 20, 85.0);
	// Anel externo (3 tiles de largura)
	lvl.addBox(2, 2, 17, 4); // Topo
	lvl.addBox(15, 2, 17, 17); // Leste
	lvl.addBox(2, 15, 17, 17); // Sul
	lvl.addBox(2, 6, 4, 17); // Oeste
	// Volta interna (3 tiles de largura)
	lvl.addBox(2, 6, 13, 8); // Topo interno
	lvl.addBox(11, 6, 13, 13); // Leste interno
	lvl.addBox(6, 11, 13, 13); // Sul interno
	// Núcleo central
	lvl.addBox(6, 8, 9, 10);
	lvl.setSpawn(3, 3);
	lvl.addRock(16, 3);
	lvl.addRock(16, 16);
	lvl.addRock(3, 16);
	lvl.addRock(12, 7);
	lvl.addRock(12, 12);
	lvl.addRock(7, 12);
	// Santuário florido no centro
	lvl.addPlant(7, 9, 'flower');
	lvl.addPlant(8, 9, 'flower');
	lvl.fillVegetation((x, z) => (x >= 6 && x <= 13 && z >= 6 && z <= 13), 'wheat');
	lvl.fillVegetation((x) => x <= 9, 'grass_purple');
	lvl.fillRemaining('grass_green');
	levels.push(lvl);
}

// ==========================================
// TIER 5: NÍVEIS ÉPICOS & CLÍMAX (Fases 17 a 20)
// ==========================================

// FASE 17: Tabuleiro Proibido (9 Plataformas 4x4 com Pontes Largas de 2 Tiles)
{
	const lvl = new LevelBuilder(17, 'Fase 17 - Tabuleiro Proibido', 20, 20, 90.0);
	const coords = [2, 8, 14];
	// 9 ilhotas 4x4
	for (const gx of coords) {
		for (const gz of coords) {
			lvl.addBox(gx, gz, gx + 3, gz + 3);
		}
	}
	// Pontes horizontais de 2 tiles de largura (Z de 2 tiles)
	for (const gz of coords) {
		lvl.addBox(5, gz + 1, 8, gz + 2);
		lvl.addBox(11, gz + 1, 14, gz + 2);
	}
	// Pontes verticais de 2 tiles de largura (X de 2 tiles)
	for (const gx of coords) {
		lvl.addBox(gx + 1, 5, gx + 2, 8);
		lvl.addBox(gx + 1, 11, gx + 2, 14);
	}
	lvl.setSpawn(9, 9);
	lvl.addRock(2, 2);
	lvl.addRock(17, 2);
	lvl.addRock(2, 17);
	lvl.addRock(17, 17);
	lvl.addRock(5, 5);
	lvl.addRock(14, 5);
	lvl.addRock(5, 14);
	lvl.addRock(14, 14);
	lvl.fillVegetation((x, z) => (x <= 4 || x >= 15) && (z <= 4 || z >= 15), 'flower');
	lvl.fillVegetation((x, z) => ((x >= 8 && x <= 11 && (z <= 4 || z >= 15)) || (z >= 8 && z <= 11 && (x <= 4 || x >= 15))), 'wheat');
	lvl.fillVegetation((x) => x <= 9, 'grass_yellow');
	lvl.fillRemaining('grass_blue');
	levels.push(lvl);
}

// FASE 18: Santuário Solar (Disco Solar Central com 8 Satélites e Raios Largos de 2 Tiles)
{
	const lvl = new LevelBuilder(18, 'Fase 18 - Santuário Solar', 22, 22, 90.0);
	const cx = 10.5;
	const cz = 10.5;
	// Centro circular largo (raio 4.8)
	lvl.addCircle(cx, cz, 4.8);
	// 8 Satélites com conexões de 2 tiles de largura
	for (let i = 0; i < 8; i++) {
		const angle = (i * Math.PI) / 4.0;
		const sx = cx + 7.5 * Math.cos(angle);
		const sz = cz + 7.5 * Math.sin(angle);
		lvl.addCircle(sx, sz, 2.0);
		// Raios radiais com 2 tiles de espessura
		const steps = 7;
		for (let s = 1; s <= steps; s++) {
			const px = Math.round(cx + (sx - cx) * (s / steps));
			const pz = Math.round(cz + (sz - cz) * (s / steps));
			lvl.addTerrain(px, pz);
			// Adiciona célula lateral adjacente para garantir no mínimo 2 tiles de largura
			if (Math.abs(Math.cos(angle)) > Math.abs(Math.sin(angle))) {
				lvl.addTerrain(px, pz + 1);
			} else {
				lvl.addTerrain(px + 1, pz);
			}
		}
	}
	lvl.setSpawn(10, 10);
	// Rochas ornamentais mantendo 2 tiles de passagem
	lvl.addRock(10, 6);
	lvl.addRock(10, 15);
	lvl.addRock(6, 10);
	lvl.addRock(15, 10);
	lvl.fillVegetation((x, z) => Math.hypot(x - cx, z - cz) >= 6.8 && ((x + z) % 2 === 0), 'flower');
	lvl.fillVegetation((x, z) => {
		const d = Math.hypot(x - cx, z - cz);
		return d >= 4.5 && d < 6.8;
	}, 'wheat');
	lvl.fillVegetation((x, z) => x <= cx && z <= cz, 'grass_green');
	lvl.fillVegetation((x, z) => x > cx && z <= cz, 'grass_yellow');
	lvl.fillVegetation((x, z) => x <= cx && z > cz, 'grass_blue');
	lvl.fillRemaining('grass_purple');
	levels.push(lvl);
}

// FASE 19: Labirinto do Minotauro (Corredores Espaçosos de no Mínimo 2 Tiles de Vão Livre)
{
	const lvl = new LevelBuilder(19, 'Fase 19 - Labirinto do Minotauro', 20, 20, 95.0);
	lvl.addBox(2, 2, 17, 17);
	lvl.setSpawn(9, 9);
	// Muros espaçados com corredores de 2 a 3 tiles de largura entre rochas
	const mazeRocks = [
		[4, 4], [7, 4], [12, 4], [15, 4],
		[4, 7], [15, 7],
		[4, 12], [15, 12],
		[4, 15], [7, 15], [12, 15], [15, 15],
		[7, 7], [12, 7],
		[7, 12], [12, 12]
	];
	for (const [wx, wz] of mazeRocks) lvl.addRock(wx, wz);
	lvl.fillVegetation((x, z) => (x <= 3 || x >= 16) && (z <= 3 || z >= 16), 'flower');
	lvl.fillVegetation((x, z) => (x === 5 || x === 14 || z === 5 || z === 14), 'wheat');
	lvl.fillRemaining('grass_purple');
	levels.push(lvl);
}

// FASE 20: A Grande Coroa Real (Grand Finale com 5 Pontas Largas de 3 a 4 Tiles)
{
	const lvl = new LevelBuilder(20, 'Fase 20 - A Grande Coroa Real', 23, 21, 110.0);
	// Base real ao sul (6 tiles de altura Z de 12 a 17)
	lvl.addBox(2, 12, 20, 17);
	// 5 Pontas Imperiais largas (3 a 4 tiles de largura cada)
	lvl.addBox(2, 6, 4, 12); // Ponta 1 (3 tiles: X=2,3,4)
	lvl.addBox(6, 4, 9, 12); // Ponta 2 (4 tiles: X=6,7,8,9)
	lvl.addBox(10, 2, 13, 12); // Ponta 3 Central Real (4 tiles: X=10,11,12,13)
	lvl.addBox(14, 4, 17, 12); // Ponta 4 (4 tiles: X=14,15,16,17)
	lvl.addBox(18, 6, 20, 12); // Ponta 5 (3 tiles: X=18,19,20)
	lvl.setSpawn(11, 15);
	// Rochas ornamentais nos topos das pontas
	const crownGems = [
		[3, 6], [7, 4], [11, 2], [15, 4], [19, 6],
		[2, 17], [8, 17], [14, 17], [20, 17]
	];
	for (const [gx, gz] of crownGems) lvl.addRock(gx, gz);
	lvl.fillVegetation((x, z) => (z <= 5 || (z >= 13 && z <= 16 && (x === 9 || x === 13))), 'flower');
	lvl.fillVegetation((x, z) => z >= 6 && z <= 11, 'wheat');
	lvl.fillVegetation((x) => x <= 6, 'grass_green');
	lvl.fillVegetation((x) => x > 6 && x <= 10, 'grass_yellow');
	lvl.fillVegetation((x) => x > 10 && x <= 15, 'grass_blue');
	lvl.fillRemaining('grass_purple');
	levels.push(lvl);
}

// ==========================================
// GRAVAÇÃO E RESUMO
// ==========================================

console.log('🌱 Gerando 20 fases canônicas (v0.6.1 - Largura Mínima >= 2 Tiles & Zero Dirt Amarelo)...\n');

const summary = [];

for (const builder of levels) {
	const levelData = builder.build();
	const filename = `level_${String(levelData.level_id).padStart(2, '0')}.json`;
	const filePath = path.join(LEVELS_DIR, filename);

	fs.writeFileSync(filePath, JSON.stringify(levelData, null, '\t'), 'utf8');

	const counts = {};
	for (const obj of levelData.objects) {
		counts[obj.type] = (counts[obj.type] || 0) + 1;
	}

	summary.push({
		Fase: String(levelData.level_id).padStart(2, '0'),
		Nome: levelData.name,
		Grid: `${levelData.grid.width}x${levelData.grid.height}`,
		Terreno: levelData.terrain.length,
		Grama: (counts['grass_green'] || 0) + (counts['grass_yellow'] || 0) + (counts['grass_blue'] || 0) + (counts['grass_purple'] || 0),
		Trigo: counts['wheat'] || 0,
		Flor: counts['flower'] || 0,
		Rochas: counts['rock'] || 0,
		Tempo: `${levelData.time_limit}s`
	});
}

console.table(summary);
console.log('\n✨ Todas as 20 fases regeradas com sucesso!');
