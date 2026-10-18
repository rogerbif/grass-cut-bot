// scripts/tools/generate_levels.js
// Gerador das 20 Fases Canônicas de Grass Cut Bot
// Executa o algoritmo de Autotile canônico e exporta os arquivos JSON oficiais em data/levels/

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

	// Quinas internas côncavas (diagonais)
	if (hasN && hasS && hasE && hasW) {
		const hasNE = terrainMap.has(`${x + 1},${z - 1}`);
		const hasNW = terrainMap.has(`${x - 1},${z - 1}`);
		const hasSW = terrainMap.has(`${x - 1},${z + 1}`);
		const hasSE = terrainMap.has(`${x + 1},${z + 1}`);

		if (!hasNE && hasNW && hasSW && hasSE) return { tile_id: 'island_corner_in', rot: 0 };
		if (!hasNW && hasNE && hasSW && hasSE) return { tile_id: 'island_corner_in', rot: 90 };
		if (!hasSW && hasNE && hasNW && hasSE) return { tile_id: 'island_corner_in', rot: 180 };
		if (!hasSE && hasNE && hasNW && hasSW) return { tile_id: 'island_corner_in', rot: 270 };
	}

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
		this.terrain = new Map(); // key -> { tile_id, rot, auto, dirt }
		this.objects = new Map(); // key -> { type, rot }
		this.spawn = { gx: Math.floor(width / 2), gz: Math.floor(height / 2), rot: 0 };
	}

	setSpawn(x, z, rot = 0) {
		this.spawn = { gx: x, gz: z, rot };
	}

	addTerrain(x, z, isDirt = false) {
		if (x < 0 || x >= this.width || z < 0 || z >= this.height) return;
		this.terrain.set(`${x},${z}`, { isDirt });
	}

	addBox(x1, z1, x2, z2, isDirt = false) {
		const minX = Math.min(x1, x2);
		const maxX = Math.max(x1, x2);
		const minZ = Math.min(z1, z2);
		const maxZ = Math.max(z1, z2);
		for (let x = minX; x <= maxX; x++) {
			for (let z = minZ; z <= maxZ; z++) {
				this.addTerrain(x, z, isDirt);
			}
		}
	}

	addCircle(cx, cz, radius, isDirt = false) {
		const r2 = radius * radius;
		const minX = Math.floor(cx - radius);
		const maxX = Math.ceil(cx + radius);
		const minZ = Math.floor(cz - radius);
		const maxZ = Math.ceil(cz + radius);
		for (let x = minX; x <= maxX; x++) {
			for (let z = minZ; z <= maxZ; z++) {
				const d2 = (x - cx) * (x - cx) + (z - cz) * (z - cz);
				if (d2 <= r2) {
					this.addTerrain(x, z, isDirt);
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
		if (this.objects.has(key)) return; // já ocupado
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
		// Resolve autotile
		const terrainList = [];
		const sortedTerrainKeys = Array.from(this.terrain.keys()).sort((a, b) => {
			const [ax, az] = a.split(',').map(Number);
			const [bx, bz] = b.split(',').map(Number);
			return az !== bz ? az - bz : ax - bx;
		});

		for (const key of sortedTerrainKeys) {
			const [gx, gz] = key.split(',').map(Number);
			const entry = this.terrain.get(key);
			if (entry.isDirt) {
				terrainList.push({
					gx,
					gz,
					tile_id: 'island_dirt',
					rot: 0,
					auto: false
				});
			} else {
				const resolved = computeTileForCell(key, this.terrain);
				terrainList.push({
					gx,
					gz,
					tile_id: resolved.tile_id,
					rot: resolved.rot,
					auto: true
				});
			}
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

// Definição das 20 Fases Canônicas
const levels = [];

// ==========================================
// TIER 1: O DESPERTAR DO JARDINEIRO (Fases 1 a 4)
// ==========================================

// FASE 01: Praia Inicial (Retângulo Amplo e Acolhedor)
{
	const lvl = new LevelBuilder(1, 'Fase 01 - Praia Inicial', 14, 10, 90.0);
	lvl.addBox(2, 2, 11, 7);
	lvl.setSpawn(6, 4);
	// Pátio central de terra leve ao redor do spawn
	lvl.addTerrain(6, 5, true);
	lvl.fillRemaining('grass_green');
	levels.push(lvl);
}

// FASE 02: Baía Amarela (Ovalada com Enseada ao Sul)
{
	const lvl = new LevelBuilder(2, 'Fase 02 - Baía Amarela', 15, 12, 85.0);
	lvl.addCircle(7, 5, 4.5);
	// Enseada escavada no sul
	lvl.removeTerrain(6, 8);
	lvl.removeTerrain(7, 8);
	lvl.removeTerrain(8, 8);
	lvl.removeTerrain(7, 7);
	lvl.setSpawn(7, 3);
	lvl.addRock(4, 3);
	lvl.addRock(10, 3);
	// Trilha central de terra
	lvl.addTerrain(7, 4, true);
	lvl.addTerrain(7, 5, true);
	lvl.fillVegetation((x, z) => z >= 5, 'grass_yellow');
	lvl.fillRemaining('grass_green');
	levels.push(lvl);
}

// FASE 03: Campos Dourados (Retângulo Chanfrado com Trigo e Rochas)
{
	const lvl = new LevelBuilder(3, 'Fase 03 - Campos Dourados', 16, 12, 85.0);
	lvl.addBox(3, 2, 12, 9);
	// Chanfra os cantos
	lvl.removeTerrain(3, 2);
	lvl.removeTerrain(12, 2);
	lvl.removeTerrain(3, 9);
	lvl.removeTerrain(12, 9);
	lvl.setSpawn(4, 5);
	// Trilha divisória
	for (let z = 3; z <= 8; z++) lvl.addTerrain(8, z, true);
	// Rochas espaçadas
	lvl.addRock(8, 3);
	lvl.addRock(8, 7);
	lvl.addRock(5, 3);
	lvl.addRock(11, 8);
	// Campo de trigo à direita
	lvl.fillVegetation((x, z) => x >= 9, 'wheat');
	lvl.fillRemaining('grass_green');
	levels.push(lvl);
}

// FASE 04: Jardim das Orquídeas (Cruz com Pátio Central e Flores)
{
	const lvl = new LevelBuilder(4, 'Fase 04 - Jardim das Orquídeas', 15, 15, 80.0);
	// Centro 7x7
	lvl.addBox(4, 4, 10, 10);
	// 4 braços cardeais 3x3
	lvl.addBox(6, 1, 8, 3); // Norte
	lvl.addBox(6, 11, 8, 13); // Sul
	lvl.addBox(1, 6, 3, 8); // Oeste
	lvl.addBox(11, 6, 13, 8); // Leste
	lvl.setSpawn(7, 7);
	// Pátio central de terra
	lvl.addBox(6, 6, 8, 8, true);
	// Rochas nas quinas internas
	lvl.addRock(5, 5);
	lvl.addRock(9, 5);
	lvl.addRock(5, 9);
	lvl.addRock(9, 9);
	// Flores nas extremidades das alas
	lvl.fillVegetation((x, z) => (z <= 3 || z >= 11 || x <= 3 || x >= 11), 'flower');
	// Trigo circundando o pátio
	lvl.fillVegetation((x, z) => (x >= 4 && x <= 10 && z >= 4 && z <= 10 && (x === 4 || x === 10 || z === 4 || z === 10)), 'wheat');
	lvl.fillRemaining('grass_green');
	levels.push(lvl);
}

// ==========================================
// TIER 2: EXPANSÃO GEOGRÁFICA & ISTMOS (Fases 5 a 8)
// ==========================================

// FASE 05: Ilhas Gêmeas (Duas Ilhas Circulares Unidas por Istmo)
{
	const lvl = new LevelBuilder(5, 'Fase 05 - Ilhas Gêmeas', 18, 11, 85.0);
	lvl.addCircle(4, 5, 3.4);
	lvl.addCircle(13, 5, 3.4);
	// Ponte de terra de 2 blocos
	lvl.addBox(7, 4, 10, 5, true);
	lvl.setSpawn(4, 5);
	lvl.addRock(7, 3);
	lvl.addRock(7, 6);
	lvl.addRock(10, 3);
	lvl.addRock(10, 6);
	lvl.addRock(15, 5);
	// Campo de trigo na parte oriental
	lvl.fillVegetation((x, z) => x >= 13 && (z === 4 || z === 6), 'wheat');
	lvl.fillVegetation((x) => x >= 11, 'grass_yellow');
	lvl.fillRemaining('grass_green');
	levels.push(lvl);
}

// FASE 06: Lagoa Serena (Atol em Anel Circular - Donut)
{
	const lvl = new LevelBuilder(6, 'Fase 06 - Lagoa Serena', 16, 16, 80.0);
	lvl.addCircle(7.5, 7.5, 6.2);
	lvl.removeCircle(7.5, 7.5, 2.4);
	lvl.setSpawn(7, 2);
	// Rochas distribuídas pelo anel
	lvl.addRock(2, 7);
	lvl.addRock(13, 7);
	lvl.addRock(4, 11);
	lvl.addRock(11, 11);
	lvl.addRock(7, 13);
	lvl.addRock(11, 4);
	// Flores perto da lagoa interna
	lvl.fillVegetation((x, z) => {
		const d = Math.hypot(x - 7.5, z - 7.5);
		return d >= 2.5 && d <= 3.6 && ((x + z) % 2 === 0);
	}, 'flower');
	// Grama azul na orla externa
	lvl.fillVegetation((x, z) => {
		const d = Math.hypot(x - 7.5, z - 7.5);
		return d >= 4.5;
	}, 'grass_blue');
	lvl.fillRemaining('grass_green');
	levels.push(lvl);
}

// FASE 07: Vale da Ampulheta (Dois Platôs com Gargalo Central)
{
	const lvl = new LevelBuilder(7, 'Fase 07 - Vale da Ampulheta', 16, 16, 80.0);
	// Platô Norte
	lvl.addBox(3, 2, 12, 6);
	// Platô Sul
	lvl.addBox(3, 9, 12, 13);
	// Gargalo central
	lvl.addBox(6, 7, 9, 8, true);
	lvl.setSpawn(7, 12);
	// Rochas estreitando o gargalo
	lvl.addRock(5, 7);
	lvl.addRock(10, 7);
	lvl.addRock(5, 8);
	lvl.addRock(10, 8);
	lvl.addRock(4, 4);
	lvl.addRock(11, 4);
	// Norte: flores e trigo
	lvl.fillVegetation((x, z) => z <= 4 && (x === 4 || x === 7 || x === 10), 'flower');
	lvl.fillVegetation((x, z) => z <= 5, 'wheat');
	lvl.fillRemaining('grass_yellow');
	levels.push(lvl);
}

// FASE 08: Três Picos (Arquipélago Tríade em Y)
{
	const lvl = new LevelBuilder(8, 'Fase 08 - Três Picos', 19, 17, 85.0);
	// Hub central
	lvl.addCircle(9, 8, 2.5, true);
	// 3 picos
	lvl.addCircle(9, 3, 2.8); // Norte
	lvl.addCircle(4, 13, 2.8); // Sudoeste
	lvl.addCircle(14, 13, 2.8); // Sudeste
	// Pontes conectando os 3 picos ao hub
	lvl.addBox(8, 5, 10, 6, true);
	lvl.addBox(6, 10, 8, 11, true);
	lvl.addBox(10, 10, 12, 11, true);
	lvl.setSpawn(9, 8);
	// Rochas nas bifurcações
	lvl.addRock(7, 7);
	lvl.addRock(11, 7);
	lvl.addRock(9, 10);
	lvl.addRock(4, 13);
	lvl.addRock(14, 13);
	lvl.addRock(9, 2);
	lvl.addRock(9, 5);
	// Biomas nos 3 picos
	lvl.fillVegetation((x, z) => z <= 4 && (x === 8 || x === 10), 'flower');
	lvl.fillVegetation((x, z) => z <= 5, 'wheat');
	lvl.fillVegetation((x, z) => x <= 6 && z >= 11, 'grass_green');
	lvl.fillVegetation((x, z) => x >= 12 && z >= 11, 'grass_blue');
	lvl.fillRemaining('grass_yellow');
	levels.push(lvl);
}

// ==========================================
// TIER 3: DESAFIO TÁTICO & CHICANES (Fases 9 a 12)
// ==========================================

// FASE 09: Serpentina de Coral (Península Sinuosa em S)
{
	const lvl = new LevelBuilder(9, 'Fase 09 - Serpentina de Coral', 18, 17, 80.0);
	// Topo da serpentina (Oeste para Leste)
	lvl.addBox(2, 2, 15, 5);
	// Curva 1 descendo à direita
	lvl.addBox(12, 5, 15, 9);
	// Meio da serpentina (Leste para Oeste)
	lvl.addBox(2, 7, 13, 10);
	// Curva 2 descendo à esquerda
	lvl.addBox(2, 10, 5, 14);
	// Fundo da serpentina (Oeste para Leste)
	lvl.addBox(2, 12, 15, 14);
	lvl.setSpawn(3, 3);
	// Rochas nos cotovelos internos
	lvl.addRock(11, 6);
	lvl.addRock(6, 9);
	lvl.addRock(6, 11);
	lvl.addRock(12, 4);
	lvl.addRock(3, 8);
	lvl.addRock(14, 13);
	lvl.addRock(8, 3);
	lvl.addRock(8, 13);
	// Trilha de terra no centro da pista
	lvl.addTerrain(4, 3, true);
	lvl.addTerrain(5, 3, true);
	lvl.addTerrain(13, 7, true);
	lvl.addTerrain(4, 9, true);
	lvl.addTerrain(3, 11, true);
	lvl.fillVegetation((x, z) => z >= 11, 'wheat');
	lvl.fillVegetation((x, z) => z >= 7 && z <= 10, 'grass_yellow');
	lvl.fillRemaining('grass_green');
	levels.push(lvl);
}

// FASE 10: Labirinto das Pedras (Ilha com Paredes de Rocha)
{
	const lvl = new LevelBuilder(10, 'Fase 10 - Labirinto das Pedras', 17, 17, 85.0);
	lvl.addBox(2, 2, 14, 14);
	lvl.setSpawn(8, 8);
	lvl.addBox(7, 7, 9, 9, true); // Pátio central
	// Rochas alinhadas formando corredores labirínticos
	const rocks = [
		[4, 4], [5, 4], [6, 4],
		[10, 4], [11, 4], [12, 4],
		[4, 7], [4, 8],
		[12, 8], [12, 9],
		[4, 12], [5, 12], [6, 12],
		[10, 12], [11, 12]
	];
	for (const [rx, rz] of rocks) lvl.addRock(rx, rz);
	lvl.fillVegetation((x, z) => (x <= 3 || x >= 13) && (z <= 3 || z >= 13), 'flower');
	lvl.fillVegetation((x, z) => (x >= 5 && x <= 11 && (z === 5 || z === 11)), 'wheat');
	lvl.fillRemaining('grass_purple');
	levels.push(lvl);
}

// FASE 11: Trevo da Sorte (4 Pétalas Tangentes ao Centro)
{
	const lvl = new LevelBuilder(11, 'Fase 11 - Trevo da Sorte', 18, 18, 85.0);
	// Centro sólido
	lvl.addBox(7, 7, 10, 10, true);
	// 4 pétalas
	lvl.addCircle(8.5, 4.5, 3.2); // Norte
	lvl.addCircle(8.5, 12.5, 3.2); // Sul
	lvl.addCircle(4.5, 8.5, 3.2); // Oeste
	lvl.addCircle(12.5, 8.5, 3.2); // Leste
	lvl.setSpawn(8, 8);
	// Rochas nas reentrâncias
	lvl.addRock(6, 6);
	lvl.addRock(11, 6);
	lvl.addRock(6, 11);
	lvl.addRock(11, 11);
	lvl.addRock(8, 2);
	lvl.addRock(8, 15);
	lvl.addRock(2, 8);
	lvl.addRock(15, 8);
	// Flores no coração de cada pétala
	lvl.addPlant(8, 4, 'flower');
	lvl.addPlant(9, 4, 'flower');
	lvl.addPlant(8, 13, 'flower');
	lvl.addPlant(9, 13, 'flower');
	lvl.addPlant(4, 8, 'flower');
	lvl.addPlant(4, 9, 'flower');
	lvl.addPlant(13, 8, 'flower');
	lvl.addPlant(13, 9, 'flower');
	// Trigo circundando
	lvl.fillVegetation((x, z) => (x >= 6 && x <= 11 && z >= 6 && z <= 11 && !lvl.terrain.get(`${x},${z}`)?.isDirt), 'wheat');
	// 4 cores nas 4 pétalas
	lvl.fillVegetation((x, z) => z <= 6, 'grass_green');
	lvl.fillVegetation((x, z) => z >= 11, 'grass_yellow');
	lvl.fillVegetation((x, z) => x <= 6, 'grass_blue');
	lvl.fillRemaining('grass_purple');
	levels.push(lvl);
}

// FASE 12: Estrela do Oceano (Estrela de 5 Pontas)
{
	const lvl = new LevelBuilder(12, 'Fase 12 - Estrela do Oceano', 19, 19, 80.0);
	const cx = 9.5;
	const cz = 9.5;
	// Desenha a estrela geometricamente por raio angular
	for (let x = 0; x < 19; x++) {
		for (let z = 0; z < 19; z++) {
			const dx = x - cx;
			const dz = z - cz;
			const dist = Math.hypot(dx, dz);
			let angle = Math.atan2(dz, dx);
			const starR = 4.2 + 3.8 * Math.cos(5 * angle);
			if (dist <= starR) {
				lvl.addTerrain(x, z);
			}
		}
	}
	lvl.setSpawn(9, 9);
	lvl.addCircle(cx, cz, 2.0, true); // Centro de terra
	// Rochas nas reentrâncias entre pontas
	lvl.addRock(7, 6);
	lvl.addRock(12, 6);
	lvl.addRock(6, 11);
	lvl.addRock(13, 11);
	lvl.addRock(9, 14);
	lvl.addRock(9, 5);
	lvl.addRock(5, 9);
	lvl.addRock(14, 9);
	// Flores nas pontas da estrela (distância alta)
	lvl.fillVegetation((x, z) => Math.hypot(x - cx, z - cz) >= 6.0, 'flower');
	lvl.fillVegetation((x, z) => {
		const d = Math.hypot(x - cx, z - cz);
		return d >= 3.8 && d < 6.0;
	}, 'wheat');
	lvl.fillVegetation((x) => x <= cx, 'grass_blue');
	lvl.fillRemaining('grass_purple');
	levels.push(lvl);
}

// ==========================================
// TIER 4: MAESTRIA & ECONOMIA (Fases 13 a 16)
// ==========================================

// FASE 13: Tridente de Netuno (Base Sul com 3 Hastes ao Norte)
{
	const lvl = new LevelBuilder(13, 'Fase 13 - Tridente de Netuno', 18, 17, 80.0);
	// Base Sul
	lvl.addBox(2, 11, 15, 14);
	// 3 Dentes do tridente
	lvl.addBox(3, 2, 5, 11); // Esquerda
	lvl.addBox(8, 2, 10, 11); // Centro
	lvl.addBox(13, 2, 15, 11); // Direita
	lvl.setSpawn(9, 13);
	// Trilha de terra conectora
	lvl.addBox(3, 12, 14, 13, true);
	// Rochas nos ápices
	lvl.addRock(2, 11);
	lvl.addRock(6, 11);
	lvl.addRock(7, 11);
	lvl.addRock(11, 11);
	lvl.addRock(12, 11);
	lvl.addRock(16, 11);
	lvl.addRock(4, 6);
	lvl.addRock(9, 6);
	lvl.addRock(14, 6);
	lvl.addRock(4, 2);
	lvl.addRock(14, 2);
	// Flores no topo das pontas
	lvl.fillVegetation((x, z) => z <= 4, 'flower');
	// Trigo denso nas hastes
	lvl.fillVegetation((x, z) => z >= 5 && z <= 10, 'wheat');
	lvl.fillRemaining('grass_green');
	levels.push(lvl);
}

// FASE 14: Coração Selvagem (Silhueta Cardioide)
{
	const lvl = new LevelBuilder(14, 'Fase 14 - Coração Selvagem', 18, 18, 80.0);
	const cx = 8.5;
	const cz = 7.5;
	for (let x = 1; x <= 16; x++) {
		for (let z = 1; z <= 16; z++) {
			const nx = (x - cx) / 6.0;
			const nz = -(z - cz) / 6.0;
			const term = nx * nx + nz * nz - 1.0;
			if (term * term * term - nx * nx * nz * nz * nz <= 0.05) {
				lvl.addTerrain(x, z);
			}
		}
	}
	lvl.setSpawn(8, 12);
	// Rochas nas curvas
	lvl.addRock(8, 5); // Fenda superior do coração
	lvl.addRock(4, 4);
	lvl.addRock(13, 4);
	lvl.addRock(2, 7);
	lvl.addRock(15, 7);
	lvl.addRock(4, 11);
	lvl.addRock(13, 11);
	lvl.addRock(8, 14);
	// Flores no núcleo central
	lvl.fillVegetation((x, z) => Math.hypot(x - cx, z - cz) <= 2.2, 'flower');
	lvl.fillVegetation((x, z) => {
		const d = Math.hypot(x - cx, z - cz);
		return d > 2.2 && d <= 4.0;
	}, 'wheat');
	lvl.fillRemaining('grass_purple');
	levels.push(lvl);
}

// FASE 15: Passadiço dos Abismos (4 Ilhotas em Degraus Lineares)
{
	const lvl = new LevelBuilder(15, 'Fase 15 - Passadiço dos Abismos', 22, 12, 85.0);
	// 4 Ilhotas 4x4
	lvl.addBox(1, 4, 4, 7); // Ilha 1
	lvl.addBox(6, 2, 9, 5); // Ilha 2
	lvl.addBox(11, 6, 14, 9); // Ilha 3
	lvl.addBox(16, 3, 19, 6); // Ilha 4
	// Pontes de ligação (2 blocos de largura)
	lvl.addBox(4, 4, 6, 5, true);
	lvl.addBox(9, 4, 11, 6, true);
	lvl.addBox(14, 5, 16, 6, true);
	lvl.setSpawn(2, 5);
	// Rochas nas cabeceiras das pontes
	lvl.addRock(4, 3);
	lvl.addRock(4, 6);
	lvl.addRock(6, 1);
	lvl.addRock(9, 3);
	lvl.addRock(11, 5);
	lvl.addRock(14, 7);
	lvl.addRock(16, 2);
	lvl.addRock(19, 3);
	// Progressão de tipos pelas 4 ilhas
	lvl.fillVegetation((x) => x >= 17, 'flower');
	lvl.fillVegetation((x) => x >= 11 && x <= 14, 'wheat');
	lvl.fillVegetation((x) => x >= 6 && x <= 9, 'grass_blue');
	lvl.fillRemaining('grass_yellow');
	levels.push(lvl);
}

// FASE 16: Fortaleza Espiral (Espiral em Caracol até o Centro)
{
	const lvl = new LevelBuilder(16, 'Fase 16 - Fortaleza Espiral', 18, 18, 85.0);
	// Quadrado externo
	lvl.addBox(2, 2, 15, 3); // Topo
	lvl.addBox(14, 2, 15, 15); // Leste
	lvl.addBox(2, 14, 15, 15); // Sul
	lvl.addBox(2, 5, 3, 15); // Oeste
	// Espira 2
	lvl.addBox(2, 5, 12, 6); // Topo interno
	lvl.addBox(11, 5, 12, 12); // Leste interno
	lvl.addBox(5, 11, 12, 12); // Sul interno
	lvl.addBox(5, 8, 6, 12); // Oeste interno
	// Núcleo central
	lvl.addBox(7, 8, 9, 9, true);
	lvl.setSpawn(2, 2);
	// Rochas nos cotovelos da espiral
	lvl.addRock(14, 3);
	lvl.addRock(14, 14);
	lvl.addRock(3, 14);
	lvl.addRock(3, 5);
	lvl.addRock(11, 6);
	lvl.addRock(11, 11);
	lvl.addRock(6, 11);
	lvl.addRock(6, 8);
	// Santuário florido no centro
	lvl.addPlant(8, 8, 'flower');
	lvl.addPlant(8, 9, 'flower');
	lvl.addPlant(9, 8, 'flower');
	lvl.addPlant(9, 9, 'flower');
	lvl.fillVegetation((x, z) => (x >= 5 && x <= 12 && z >= 5 && z <= 12), 'wheat');
	lvl.fillVegetation((x) => x <= 8, 'grass_purple');
	lvl.fillRemaining('grass_green');
	levels.push(lvl);
}

// ==========================================
// TIER 5: NÍVEIS ÉPICOS & CLÍMAX (Fases 17 a 20)
// ==========================================

// FASE 17: Tabuleiro Proibido (Mosaico de 9 Plataformas 3x3 com Lagoas)
{
	const lvl = new LevelBuilder(17, 'Fase 17 - Tabuleiro Proibido', 19, 19, 90.0);
	// 9 ilhotas 3x3 em grade
	const coords = [2, 8, 14];
	for (const gx of coords) {
		for (const gz of coords) {
			lvl.addBox(gx, gz, gx + 2, gz + 2);
		}
	}
	// Pontes horizontais
	for (const gz of coords) {
		lvl.addBox(5, gz + 1, 7, gz + 1, true);
		lvl.addBox(11, gz + 1, 13, gz + 1, true);
	}
	// Pontes verticais
	for (const gx of coords) {
		lvl.addBox(gx + 1, 5, gx + 1, 7, true);
		lvl.addBox(gx + 1, 11, gx + 1, 13, true);
	}
	lvl.setSpawn(9, 9);
	// Rochas nas quinas das lagoas
	lvl.addRock(2, 2);
	lvl.addRock(14, 2);
	lvl.addRock(2, 14);
	lvl.addRock(14, 14);
	lvl.addRock(5, 5);
	lvl.addRock(13, 5);
	lvl.addRock(5, 13);
	lvl.addRock(13, 13);
	lvl.addRock(8, 5);
	lvl.addRock(10, 5);
	lvl.addRock(8, 13);
	lvl.addRock(10, 13);
	// Flores nas 4 ilhas de quina
	lvl.fillVegetation((x, z) => (x <= 4 || x >= 14) && (z <= 4 || z >= 14), 'flower');
	// Trigo nas 4 ilhas cardeais
	lvl.fillVegetation((x, z) => ((x >= 8 && x <= 10 && (z <= 4 || z >= 14)) || (z >= 8 && z <= 10 && (x <= 4 || x >= 14))), 'wheat');
	lvl.fillVegetation((x) => x <= 9, 'grass_yellow');
	lvl.fillRemaining('grass_blue');
	levels.push(lvl);
}

// FASE 18: Santuário Solar (Disco Solar Central com 8 Satélites Radiais)
{
	const lvl = new LevelBuilder(18, 'Fase 18 - Santuário Solar', 20, 20, 90.0);
	const cx = 9.5;
	const cz = 9.5;
	// Centro circular
	lvl.addCircle(cx, cz, 4.2, true);
	// 8 Satélites
	for (let i = 0; i < 8; i++) {
		const angle = (i * Math.PI) / 4.0;
		const sx = cx + 6.8 * Math.cos(angle);
		const sz = cz + 6.8 * Math.sin(angle);
		lvl.addCircle(sx, sz, 1.8);
		// Pontes radiais
		const steps = 6;
		for (let s = 1; s <= steps; s++) {
			const px = Math.round(cx + (sx - cx) * (s / steps));
			const pz = Math.round(cz + (sz - cz) * (s / steps));
			lvl.addTerrain(px, pz, true);
		}
	}
	lvl.setSpawn(9, 9);
	// Rochas nas entradas dos raios
	for (let i = 0; i < 8; i++) {
		const angle = (i * Math.PI) / 4.0 + 0.35;
		const rx = Math.round(cx + 3.8 * Math.cos(angle));
		const rz = Math.round(cz + 3.8 * Math.sin(angle));
		lvl.addRock(rx, rz);
	}
	// Flores selecionadas nos satélites externos
	lvl.fillVegetation((x, z) => Math.hypot(x - cx, z - cz) >= 6.2 && ((x + z) % 2 === 0), 'flower');
	lvl.fillVegetation((x, z) => {
		const d = Math.hypot(x - cx, z - cz);
		return d >= 4.0 && d < 6.2;
	}, 'wheat');
	lvl.fillVegetation((x, z) => x <= cx && z <= cz, 'grass_green');
	lvl.fillVegetation((x, z) => x > cx && z <= cz, 'grass_yellow');
	lvl.fillVegetation((x, z) => x <= cx && z > cz, 'grass_blue');
	lvl.fillRemaining('grass_purple');
	levels.push(lvl);
}

// FASE 19: Labirinto do Minotauro (Muralhas de Pedra e Ruelas Estreitas)
{
	const lvl = new LevelBuilder(19, 'Fase 19 - Labirinto do Minotauro', 19, 19, 95.0);
	lvl.addBox(2, 2, 16, 16);
	lvl.setSpawn(9, 9);
	lvl.addBox(8, 8, 10, 10, true);
	// Muros espaçados e navegáveis para o cortador não ficar preso
	const mazeRocks = [
		// Cantos e colunas
		[4, 4], [5, 4], [7, 4], [11, 4], [13, 4], [14, 4],
		[4, 7], [4, 11], [14, 7], [14, 11],
		[4, 14], [5, 14], [7, 14], [11, 14], [13, 14], [14, 14],
		// Barreiras internas
		[6, 6], [7, 6], [11, 6], [12, 6],
		[6, 8], [12, 8], [6, 10], [12, 10],
		[6, 12], [7, 12], [11, 12], [12, 12]
	];
	for (const [wx, wz] of mazeRocks) lvl.addRock(wx, wz);
	// Flores nos 4 cantos secretos do labirinto
	lvl.fillVegetation((x, z) => (x <= 3 || x >= 15) && (z <= 3 || z >= 15), 'flower');
	// Trigo denso nos corredores intermediários
	lvl.fillVegetation((x, z) => (x === 5 || x === 13 || z === 5 || z === 13), 'wheat');
	lvl.fillRemaining('grass_purple');
	levels.push(lvl);
}

// FASE 20: A Grande Coroa Real (Grand Finale Épico)
{
	const lvl = new LevelBuilder(20, 'Fase 20 - A Grande Coroa Real', 22, 20, 110.0);
	// Base real ao sul
	lvl.addBox(2, 12, 19, 17);
	// 5 Pontas Imperiais ao norte
	lvl.addBox(2, 5, 4, 12); // Ponta 1 (Esquerda)
	lvl.addBox(6, 3, 8, 12); // Ponta 2 (Média Alta)
	lvl.addBox(10, 1, 12, 12); // Ponta 3 Real (Mais Alta Central)
	lvl.addBox(14, 3, 16, 12); // Ponta 4 (Média Alta)
	lvl.addBox(18, 5, 20, 12); // Ponta 5 (Direita)
	// Pátio do trono ao sul
	lvl.addBox(8, 13, 13, 16, true);
	lvl.setSpawn(11, 15);
	// Rochas ornamentais como "joias da coroa"
	const crownGems = [
		[3, 5], [7, 3], [11, 1], [15, 3], [19, 5], // Topo das pontas
		[5, 12], [9, 12], [13, 12], [17, 12], // Gargalos das pontas
		[2, 17], [7, 17], [14, 17], [19, 17], // Base sul
		[7, 14], [14, 14] // Guardas do trono
	];
	for (const [gx, gz] of crownGems) lvl.addRock(gx, gz);
	// Flores imperiais no trono e nas 5 pontas
	lvl.fillVegetation((x, z) => (z <= 4 || (z >= 13 && z <= 16 && (x === 9 || x === 12))), 'flower');
	// Trigo real cobrindo as 5 hastes
	lvl.fillVegetation((x, z) => z >= 5 && z <= 11, 'wheat');
	// Mosaico com as 4 cores de grama
	lvl.fillVegetation((x) => x <= 6, 'grass_green');
	lvl.fillVegetation((x) => x > 6 && x <= 10, 'grass_yellow');
	lvl.fillVegetation((x) => x > 10 && x <= 15, 'grass_blue');
	lvl.fillRemaining('grass_purple');
	levels.push(lvl);
}

// ==========================================
// GRAVAÇÃO E RESUMO
// ==========================================

console.log('🌱 Iniciando geração das 20 fases canônicas de Grass Cut Bot...\n');

const summary = [];

for (const builder of levels) {
	const levelData = builder.build();
	const filename = `level_${String(levelData.level_id).padStart(2, '0')}.json`;
	const filePath = path.join(LEVELS_DIR, filename);

	fs.writeFileSync(filePath, JSON.stringify(levelData, null, '\t'), 'utf8');

	// Contagem de objetos
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
console.log('\n✨ Todas as 20 fases geradas com sucesso em data/levels/!');
