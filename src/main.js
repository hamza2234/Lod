import * as THREE from "three";
import { RoundedBoxGeometry } from "three/addons/geometries/RoundedBoxGeometry.js";
import "./styles.css";

const skins = [
  {
    id: "royal-gold",
    name: "Royal Gold",
    rarity: "Legendary",
    cardLabel: "ذهب ملكي",
    description:
      "نرد ذهبي ملكي بحواف دائرية، نقاط مضيئة، ولمعة سينمائية عند التوقف.",
    body: "#f6c75f",
    side: "#8b4b13",
    pips: "#fff6c3",
    accent: "#ffd86b",
    glow: "rgba(255, 216, 107, 0.32)",
    metalness: 0.88,
    roughness: 0.18,
    clearcoat: 1,
  },
  {
    id: "inferno",
    name: "Inferno Core",
    rarity: "Epic",
    cardLabel: "نار وبركان",
    description:
      "نرد أسود محروق بقلب ناري، يطلق شررًا أحمر عند الرمي ويضيء عند الرقم 6.",
    body: "#1b0b0a",
    side: "#ff4b1f",
    pips: "#ffd3a4",
    accent: "#ff5c25",
    glow: "rgba(255, 92, 37, 0.34)",
    metalness: 0.44,
    roughness: 0.28,
    clearcoat: 0.78,
  },
  {
    id: "frost",
    name: "Frost Crystal",
    rarity: "Rare",
    cardLabel: "كريستال جليدي",
    description:
      "نرد شفاف بلون الجليد مع ضباب بارد ونقاط كريستالية ناعمة أثناء الدوران.",
    body: "#8adcf7",
    side: "#defbff",
    pips: "#ffffff",
    accent: "#8deaff",
    glow: "rgba(141, 234, 255, 0.3)",
    metalness: 0.2,
    roughness: 0.08,
    clearcoat: 1,
    transparent: true,
  },
  {
    id: "galaxy",
    name: "Galaxy Void",
    rarity: "Mythic",
    cardLabel: "مجرة بنفسجية",
    description:
      "نرد فضائي داكن مع نقاط تشبه النجوم وهالة بنفسجية تتحرك حوله عند الرمي.",
    body: "#16122d",
    side: "#7f5cff",
    pips: "#f3e8ff",
    accent: "#a77dff",
    glow: "rgba(167, 125, 255, 0.35)",
    metalness: 0.58,
    roughness: 0.18,
    clearcoat: 1,
  },
  {
    id: "emerald",
    name: "Emerald Royal",
    rarity: "Epic",
    cardLabel: "زمرد فاخر",
    description:
      "نرد زمردي لامع بنقاط ذهبية وحركة هادئة تناسب الجوائز والبطولات.",
    body: "#0fa66f",
    side: "#b7ffbd",
    pips: "#ffe49c",
    accent: "#39ff9e",
    glow: "rgba(57, 255, 158, 0.28)",
    metalness: 0.62,
    roughness: 0.16,
    clearcoat: 1,
  },
];

const canvas = document.querySelector("#scene");
const rollButton = document.querySelector("#rollButton");
const resultValue = document.querySelector("#resultValue");
const selectedDiceName = document.querySelector("#selectedDiceName");
const diceRarity = document.querySelector("#diceRarity");
const diceDescription = document.querySelector("#diceDescription");
const skinCards = document.querySelector("#skinCards");

const scene = new THREE.Scene();
scene.fog = new THREE.FogExp2(0x06070c, 0.045);

const camera = new THREE.PerspectiveCamera(
  42,
  window.innerWidth / window.innerHeight,
  0.1,
  100,
);
camera.position.set(0, 3.45, 7.4);

const renderer = new THREE.WebGLRenderer({
  canvas,
  antialias: true,
  alpha: true,
  powerPreference: "high-performance",
});
renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
renderer.setSize(window.innerWidth, window.innerHeight);
renderer.outputColorSpace = THREE.SRGBColorSpace;
renderer.toneMapping = THREE.ACESFilmicToneMapping;
renderer.toneMappingExposure = 1.18;
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;

const clock = new THREE.Clock();
const raycaster = new THREE.Raycaster();
const pointer = new THREE.Vector2();

let selectedSkin = skins[0];
let diceModel;
let rollState = null;

const diceRoot = new THREE.Group();
diceRoot.position.y = 0.26;
scene.add(diceRoot);

const floorMaterial = new THREE.MeshPhysicalMaterial({
  color: 0x111827,
  roughness: 0.34,
  metalness: 0.2,
  clearcoat: 0.9,
  clearcoatRoughness: 0.24,
});
const floor = new THREE.Mesh(new THREE.CircleGeometry(4.25, 96), floorMaterial);
floor.rotation.x = -Math.PI / 2;
floor.position.y = -1.08;
floor.receiveShadow = true;
scene.add(floor);

const pedestal = new THREE.Mesh(
  new THREE.CylinderGeometry(1.85, 2.15, 0.34, 96),
  new THREE.MeshPhysicalMaterial({
    color: 0x151827,
    metalness: 0.62,
    roughness: 0.26,
    clearcoat: 1,
  }),
);
pedestal.position.y = -0.88;
pedestal.receiveShadow = true;
pedestal.castShadow = true;
scene.add(pedestal);

const ring = new THREE.Mesh(
  new THREE.TorusGeometry(2.18, 0.018, 12, 160),
  new THREE.MeshBasicMaterial({ color: selectedSkin.accent }),
);
ring.rotation.x = Math.PI / 2;
ring.position.y = -0.66;
scene.add(ring);

const softAmbient = new THREE.HemisphereLight(0xbfd7ff, 0x100807, 1.2);
scene.add(softAmbient);

const keyLight = new THREE.DirectionalLight(0xffffff, 3.8);
keyLight.position.set(-3.5, 6, 4.5);
keyLight.castShadow = true;
keyLight.shadow.mapSize.set(2048, 2048);
keyLight.shadow.camera.near = 0.5;
keyLight.shadow.camera.far = 18;
scene.add(keyLight);

const rimLight = new THREE.PointLight(selectedSkin.accent, 4.2, 12);
rimLight.position.set(3.2, 2.7, 3.3);
scene.add(rimLight);

const underGlow = new THREE.PointLight(selectedSkin.accent, 3.2, 7);
underGlow.position.set(0, -0.45, 1.15);
scene.add(underGlow);

const resultQuaternions = {
  1: new THREE.Quaternion().setFromEuler(new THREE.Euler(-Math.PI / 2, 0, 0)),
  2: new THREE.Quaternion().identity(),
  3: new THREE.Quaternion().setFromEuler(new THREE.Euler(0, 0, Math.PI / 2)),
  4: new THREE.Quaternion().setFromEuler(new THREE.Euler(0, 0, -Math.PI / 2)),
  5: new THREE.Quaternion().setFromEuler(new THREE.Euler(Math.PI, 0, 0)),
  6: new THREE.Quaternion().setFromEuler(new THREE.Euler(Math.PI / 2, 0, 0)),
};

const particleGroup = new THREE.Group();
scene.add(particleGroup);
const particles = [];

buildSkinCards();
selectSkin(skins[0]);
diceRoot.quaternion.copy(resultQuaternions[1]);

rollButton.addEventListener("click", () => rollDice());
canvas.addEventListener("pointerdown", onCanvasPointerDown);
window.addEventListener("resize", onResize);

renderer.setAnimationLoop(render);

function buildSkinCards() {
  skinCards.innerHTML = "";
  skins.forEach((skin) => {
    const card = document.createElement("button");
    card.type = "button";
    card.className = "skin-card";
    card.dataset.skinId = skin.id;
    card.style.setProperty("--skin-accent", skin.accent);
    card.style.setProperty("--skin-glow", skin.glow);
    card.innerHTML = `<strong>${skin.name}</strong><span>${skin.cardLabel}</span>`;
    card.addEventListener("click", () => selectSkin(skin));
    skinCards.appendChild(card);
  });
}

function selectSkin(skin) {
  selectedSkin = skin;
  selectedDiceName.textContent = skin.name;
  diceRarity.textContent = skin.rarity;
  diceDescription.textContent = skin.description;

  document.querySelectorAll(".skin-card").forEach((card) => {
    card.classList.toggle("active", card.dataset.skinId === skin.id);
  });

  ring.material.color.set(skin.accent);
  rimLight.color.set(skin.accent);
  underGlow.color.set(skin.accent);
  floorMaterial.color.set(new THREE.Color(skin.body).multiplyScalar(0.18));

  if (diceModel) {
    diceRoot.remove(diceModel);
    disposeTree(diceModel);
  }

  diceModel = createDiceModel(skin);
  diceRoot.add(diceModel);
}

function createDiceModel(skin) {
  const group = new THREE.Group();
  const bodyMaterial = new THREE.MeshPhysicalMaterial({
    color: skin.body,
    emissive: skin.side,
    emissiveIntensity: skin.id === "inferno" ? 0.32 : 0.12,
    metalness: skin.metalness,
    roughness: skin.roughness,
    clearcoat: skin.clearcoat,
    clearcoatRoughness: 0.08,
    transparent: Boolean(skin.transparent),
    opacity: skin.transparent ? 0.78 : 1,
    transmission: skin.transparent ? 0.22 : 0,
    thickness: skin.transparent ? 1.1 : 0.1,
  });

  const cube = new THREE.Mesh(new RoundedBoxGeometry(2, 2, 2, 8, 0.18), bodyMaterial);
  cube.castShadow = true;
  cube.receiveShadow = true;
  group.add(cube);

  const bevelGlow = new THREE.Mesh(
    new RoundedBoxGeometry(2.045, 2.045, 2.045, 8, 0.2),
    new THREE.MeshBasicMaterial({
      color: skin.accent,
      transparent: true,
      opacity: 0.055,
      blending: THREE.AdditiveBlending,
    }),
  );
  group.add(bevelGlow);

  const pipMaterial = new THREE.MeshStandardMaterial({
    color: skin.pips,
    emissive: skin.accent,
    emissiveIntensity: 0.78,
    metalness: 0.3,
    roughness: 0.18,
  });

  addFacePips(group, 1, "+z", pipMaterial);
  addFacePips(group, 6, "-z", pipMaterial);
  addFacePips(group, 2, "+y", pipMaterial);
  addFacePips(group, 5, "-y", pipMaterial);
  addFacePips(group, 3, "+x", pipMaterial);
  addFacePips(group, 4, "-x", pipMaterial);

  if (skin.id === "galaxy") {
    addGalaxySpecks(group, skin);
  }

  return group;
}

function addFacePips(group, value, face, material) {
  const h = 1.011;
  const pipGeometry = new THREE.CircleGeometry(0.115, 34);
  const positions = pipLayout(value);

  positions.forEach(([a, b]) => {
    const pip = new THREE.Mesh(pipGeometry, material);
    setFaceTransform(pip, face, a, b, h);
    group.add(pip);

    const glow = new THREE.Mesh(
      new THREE.CircleGeometry(0.17, 34),
      new THREE.MeshBasicMaterial({
        color: material.emissive,
        transparent: true,
        opacity: 0.13,
        blending: THREE.AdditiveBlending,
        depthWrite: false,
      }),
    );
    setFaceTransform(glow, face, a, b, h + 0.003);
    group.add(glow);
  });
}

function pipLayout(value) {
  const o = 0.46;
  const c = 0;
  const layouts = {
    1: [[c, c]],
    2: [
      [-o, -o],
      [o, o],
    ],
    3: [
      [-o, -o],
      [c, c],
      [o, o],
    ],
    4: [
      [-o, -o],
      [-o, o],
      [o, -o],
      [o, o],
    ],
    5: [
      [-o, -o],
      [-o, o],
      [c, c],
      [o, -o],
      [o, o],
    ],
    6: [
      [-o, -o],
      [-o, c],
      [-o, o],
      [o, -o],
      [o, c],
      [o, o],
    ],
  };
  return layouts[value];
}

function setFaceTransform(mesh, face, a, b, h) {
  if (face === "+z") {
    mesh.position.set(a, b, h);
  } else if (face === "-z") {
    mesh.position.set(-a, b, -h);
    mesh.rotation.y = Math.PI;
  } else if (face === "+y") {
    mesh.position.set(a, h, -b);
    mesh.rotation.x = -Math.PI / 2;
  } else if (face === "-y") {
    mesh.position.set(a, -h, b);
    mesh.rotation.x = Math.PI / 2;
  } else if (face === "+x") {
    mesh.position.set(h, b, -a);
    mesh.rotation.y = Math.PI / 2;
  } else if (face === "-x") {
    mesh.position.set(-h, b, a);
    mesh.rotation.y = -Math.PI / 2;
  }
}

function addGalaxySpecks(group, skin) {
  const speckMaterial = new THREE.MeshBasicMaterial({ color: skin.pips });
  const speckGeometry = new THREE.SphereGeometry(0.018, 8, 8);

  for (let i = 0; i < 38; i += 1) {
    const speck = new THREE.Mesh(speckGeometry, speckMaterial);
    const face = Math.floor(Math.random() * 6);
    const a = THREE.MathUtils.randFloatSpread(1.58);
    const b = THREE.MathUtils.randFloatSpread(1.58);
    const h = 1.018;
    setFaceTransform(speck, ["+z", "-z", "+y", "-y", "+x", "-x"][face], a, b, h);
    group.add(speck);
  }
}

function rollDice() {
  if (rollState) return;

  const result = Math.floor(Math.random() * 6) + 1;
  const now = clock.getElapsedTime();
  const duration = 2.65;

  resultValue.textContent = "يدور...";
  rollButton.disabled = true;
  spawnParticles(38, selectedSkin.accent, 0.75);

  rollState = {
    start: now,
    duration,
    result,
    targetQuat: resultQuaternions[result].clone(),
    blendStarted: false,
    blendStartQuat: new THREE.Quaternion(),
    spin: new THREE.Vector3(
      THREE.MathUtils.randFloat(15, 21) * Math.PI,
      THREE.MathUtils.randFloat(18, 26) * Math.PI,
      THREE.MathUtils.randFloat(13, 19) * Math.PI,
    ),
    seed: new THREE.Vector3(
      Math.random() * Math.PI,
      Math.random() * Math.PI,
      Math.random() * Math.PI,
    ),
  };
}

function onCanvasPointerDown(event) {
  if (event.target !== canvas || rollState) return;

  pointer.x = (event.clientX / window.innerWidth) * 2 - 1;
  pointer.y = -(event.clientY / window.innerHeight) * 2 + 1;
  raycaster.setFromCamera(pointer, camera);

  const hits = raycaster.intersectObjects(diceModel.children, true);
  if (hits.length > 0) {
    rollDice();
  }
}

function render() {
  const elapsed = clock.getElapsedTime();

  ring.rotation.z = elapsed * 0.28;
  rimLight.intensity = 3.3 + Math.sin(elapsed * 2.2) * 0.9;
  underGlow.intensity = 2.2 + Math.sin(elapsed * 3.4) * 0.7;

  if (rollState) {
    updateRoll(elapsed);
  } else {
    diceRoot.position.y = 0.26 + Math.sin(elapsed * 1.35) * 0.045;
    diceRoot.rotation.y += 0.0035;
  }

  updateParticles(1 / 60);

  camera.position.x = Math.sin(elapsed * 0.24) * 0.18;
  camera.position.y = 3.35 + Math.sin(elapsed * 0.18) * 0.12;
  camera.lookAt(0, 0.05, 0);

  renderer.render(scene, camera);
}

function updateRoll(elapsed) {
  const t = Math.min((elapsed - rollState.start) / rollState.duration, 1);
  const eased = easeOutCubic(t);

  if (t < 0.78) {
    diceRoot.rotation.set(
      rollState.seed.x + rollState.spin.x * eased,
      rollState.seed.y + rollState.spin.y * eased,
      rollState.seed.z + rollState.spin.z * eased,
    );
    diceRoot.position.y =
      0.26 + Math.abs(Math.sin(t * Math.PI * 5.4)) * (1.05 - t * 0.45);
    diceRoot.scale.setScalar(1 + Math.sin(t * Math.PI) * 0.075);
  } else {
    if (!rollState.blendStarted) {
      rollState.blendStarted = true;
      rollState.blendStartQuat.copy(diceRoot.quaternion);
      spawnParticles(24, selectedSkin.accent, 0.32);
    }

    const u = smoothstep((t - 0.78) / 0.22);
    diceRoot.quaternion.slerpQuaternions(
      rollState.blendStartQuat,
      rollState.targetQuat,
      u,
    );
    diceRoot.position.y = 0.26 + Math.sin((1 - u) * Math.PI * 3) * 0.09;
    diceRoot.scale.setScalar(1 + Math.sin(u * Math.PI) * 0.04);
  }

  if (t >= 1) {
    diceRoot.quaternion.copy(rollState.targetQuat);
    diceRoot.position.y = 0.26;
    diceRoot.scale.setScalar(1);
    resultValue.textContent = String(rollState.result);
    rollButton.disabled = false;
    spawnParticles(44, selectedSkin.accent, rollState.result === 6 ? 1.1 : 0.72);
    rollState = null;
  }
}

function spawnParticles(count, color, force) {
  const material = new THREE.MeshBasicMaterial({
    color,
    transparent: true,
    opacity: 0.9,
    blending: THREE.AdditiveBlending,
    depthWrite: false,
  });
  const geometry = new THREE.SphereGeometry(0.035, 8, 8);

  for (let i = 0; i < count; i += 1) {
    const particle = new THREE.Mesh(geometry, material);
    particle.position.set(
      THREE.MathUtils.randFloatSpread(1.15),
      THREE.MathUtils.randFloat(0.1, 0.85),
      THREE.MathUtils.randFloatSpread(1.15),
    );
    particle.userData.velocity = new THREE.Vector3(
      THREE.MathUtils.randFloatSpread(1.3) * force,
      THREE.MathUtils.randFloat(0.8, 2.2) * force,
      THREE.MathUtils.randFloatSpread(1.3) * force,
    );
    particle.userData.life = THREE.MathUtils.randFloat(0.55, 1.15);
    particle.userData.maxLife = particle.userData.life;
    particles.push(particle);
    particleGroup.add(particle);
  }
}

function updateParticles(delta) {
  for (let i = particles.length - 1; i >= 0; i -= 1) {
    const particle = particles[i];
    particle.userData.life -= delta;
    particle.userData.velocity.y -= delta * 1.8;
    particle.position.addScaledVector(particle.userData.velocity, delta);
    particle.scale.setScalar(Math.max(particle.userData.life / particle.userData.maxLife, 0));

    if (particle.userData.life <= 0) {
      particleGroup.remove(particle);
      disposeTree(particle);
      particles.splice(i, 1);
    }
  }
}

function easeOutCubic(t) {
  return 1 - Math.pow(1 - t, 3);
}

function smoothstep(t) {
  const clamped = THREE.MathUtils.clamp(t, 0, 1);
  return clamped * clamped * (3 - 2 * clamped);
}

function onResize() {
  camera.aspect = window.innerWidth / window.innerHeight;
  camera.updateProjectionMatrix();
  renderer.setSize(window.innerWidth, window.innerHeight);
  renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
}

function disposeTree(object) {
  object.traverse((child) => {
    if (child.geometry) child.geometry.dispose();
    if (child.material) {
      if (Array.isArray(child.material)) {
        child.material.forEach((material) => material.dispose());
      } else {
        child.material.dispose();
      }
    }
  });
}
