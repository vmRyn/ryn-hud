<script setup lang="ts">
import { onUnmounted, ref } from 'vue'
import type { HudState, MinimapShape, SpeedStyle } from '../../types'

const SPEED_STYLES: SpeedStyle[] = ['digitalArc', 'digital', 'minimal', 'analog', 'circular']

const props = defineProps<{
  state: HudState
  vehicleScene: boolean
  adminOpen: boolean
  cinematic: boolean
  hudVisible: boolean
  speedStyle: SpeedStyle
  minimapShape: MinimapShape
}>()

const emit = defineEmits<{
  patch: [patch: Partial<HudState>]
  vehicle: [active: boolean]
  admin: [open: boolean]
  scenario: [name: string]
  cinematic: [active: boolean]
  hudVisible: [visible: boolean]
  speedStyle: [style: SpeedStyle]
  minimapShape: [shape: MinimapShape]
}>()

const open = ref(true)
const live = ref(false)
let timer: number | null = null

function setVital(key: 'health' | 'armor' | 'hunger' | 'thirst', value: number) {
  emit('patch', { [key]: value })
}

function setStress(value: number) {
  emit('patch', { stress: value })
}

function toggleVoice() {
  const talking = !props.state.voice.talking
  emit('patch', {
    voice: {
      talking,
      mode: talking ? props.state.voice.mode : props.state.voice.mode,
      radio: props.state.voice.radio,
    },
  })
}

function cycleVoiceMode() {
  const next = props.state.voice.mode >= 3 ? 1 : props.state.voice.mode + 1
  emit('patch', {
    voice: {
      talking: true,
      mode: next,
      radio: false,
    },
  })
}

function toggleCruise() {
  emit('patch', {
    vehicle: { ...props.state.vehicle, cruise: !props.state.vehicle.cruise },
  })
}

function toggleWaypoint() {
  const active = !props.state.compass.waypoint?.active
  emit('patch', {
    compass: {
      ...props.state.compass,
      waypoint: active
        ? { active: true, distance: 850, direction: 'NE' }
        : null,
    },
  })
}

function toggleRadio() {
  emit('patch', {
    voice: {
      talking: props.state.voice.talking,
      mode: props.state.voice.mode,
      radio: !props.state.voice.radio,
    },
  })
}

function toggleStamina() {
  emit('patch', {
    staminaActive: !props.state.staminaActive,
    stamina: props.state.staminaActive ? 100 : 34,
  })
}

function toggleOxygen() {
  emit('patch', {
    oxygenActive: !props.state.oxygenActive,
    oxygen: props.state.oxygenActive ? 100 : 41,
  })
}

function toggleWeapon() {
  emit('patch', {
    weapon: props.state.weapon?.show
      ? null
      : { show: true, clip: 12, reserve: 228, hasAmmo: true },
  })
}

function togglePeek() {
  const on = !props.state.identity.showMoney
  emit('patch', {
    identity: {
      ...props.state.identity,
      peek: on,
      showMoney: on,
      showJob: on,
    },
  })
}

function enterVehicle(on: boolean) {
  emit('vehicle', on)
  emit('patch', {
    vehicle: {
      ...props.state.vehicle,
      active: on,
      speed: on ? 48 : 0,
      rpm: on ? 42 : 0,
      gear: on ? '3' : 'N',
      seatbeltVisible: on,
    },
  })
}

function setSpeed(value: number) {
  emit('patch', {
    vehicle: {
      ...props.state.vehicle,
      speed: value,
      rpm: Math.min(100, Math.round(value * 0.9)),
    },
  })
}

function setFuel(value: number) {
  emit('patch', { vehicle: { ...props.state.vehicle, fuel: value } })
}

function toggleBelt() {
  emit('patch', {
    vehicle: { ...props.state.vehicle, seatbelt: !props.state.vehicle.seatbelt },
  })
}

function toggleAir() {
  const airborne = !props.state.vehicle.airborne
  emit('patch', {
    vehicle: {
      ...props.state.vehicle,
      airborne,
      altitude: airborne ? 240 : 0,
      seatbeltVisible: !airborne,
    },
  })
}

function cycleSpeedStyle() {
  const idx = SPEED_STYLES.indexOf(props.speedStyle)
  const next = SPEED_STYLES[(idx + 1) % SPEED_STYLES.length]
  emit('speedStyle', next)
  if (!props.vehicleScene) enterVehicle(true)
}

function toggleLive() {
  live.value = !live.value
  if (timer) {
    window.clearInterval(timer)
    timer = null
  }
  if (!live.value) return
  if (!props.vehicleScene) enterVehicle(true)
  timer = window.setInterval(() => {
    const speed = 28 + Math.round(Math.abs(Math.sin(Date.now() / 700) * 62))
    emit('patch', {
      vehicle: {
        ...props.state.vehicle,
        speed,
        rpm: Math.min(100, speed + 12),
        gear: String(Math.max(1, Math.min(6, Math.ceil(speed / 18)))),
        fuel: Math.max(8, props.state.vehicle.fuel - 0.05),
      },
    })
  }, 80)
}

onUnmounted(() => {
  if (timer) window.clearInterval(timer)
})
</script>

<template>
  <aside class="devtools" :class="{ collapsed: !open }">
    <header>
      <strong>Preview</strong>
      <button type="button" @click="open = !open">{{ open ? 'Hide' : 'Dev tools' }}</button>
    </header>
    <div v-if="open" class="devtools-body">
      <p>Browser mock — not sent to FiveM. Press <kbd>`</kbd> to hide.</p>
      <div class="row">
        <button type="button" :class="{ on: vehicleScene }" @click="enterVehicle(!vehicleScene)">Vehicle swipe</button>
        <button
          type="button"
          :class="{ on: minimapShape === 'circle' }"
          @click="emit('minimapShape', minimapShape === 'circle' ? 'square' : 'circle')"
        >Circle map</button>
        <button type="button" @click="cycleSpeedStyle">Speedo {{ speedStyle }}</button>
        <button type="button" :class="{ on: adminOpen }" @click="emit('admin', !adminOpen)">Admin panel</button>
        <button type="button" :class="{ on: cinematic }" @click="emit('cinematic', !cinematic)">Cinematic</button>
        <button type="button" :class="{ on: hudVisible }" @click="emit('hudVisible', !hudVisible)">HUD visible</button>
        <button type="button" :class="{ on: live }" @click="toggleLive">Live speed</button>
      </div>
      <div class="row">
        <button type="button" @click="emit('scenario', 'healthy')">Healthy</button>
        <button type="button" @click="emit('scenario', 'critical')">Critical</button>
        <button type="button" @click="emit('scenario', 'combat')">Combat</button>
      </div>
      <label>Health {{ state.health }}<input type="range" min="0" max="100" :value="state.health" @input="setVital('health', Number(($event.target as HTMLInputElement).value))" /></label>
      <label>Armor {{ state.armor }}<input type="range" min="0" max="100" :value="state.armor" @input="setVital('armor', Number(($event.target as HTMLInputElement).value))" /></label>
      <label>Hunger {{ state.hunger }}<input type="range" min="0" max="100" :value="state.hunger" @input="setVital('hunger', Number(($event.target as HTMLInputElement).value))" /></label>
      <label>Thirst {{ state.thirst }}<input type="range" min="0" max="100" :value="state.thirst" @input="setVital('thirst', Number(($event.target as HTMLInputElement).value))" /></label>
      <label>Stress {{ state.stress ?? 0 }}<input type="range" min="0" max="100" :value="state.stress ?? 0" @input="setStress(Number(($event.target as HTMLInputElement).value))" /></label>
      <label>Speed {{ state.vehicle.speed }}<input type="range" min="0" max="200" :value="state.vehicle.speed" @input="setSpeed(Number(($event.target as HTMLInputElement).value))" /></label>
      <label>Fuel {{ Math.round(state.vehicle.fuel) }}<input type="range" min="0" max="100" :value="state.vehicle.fuel" @input="setFuel(Number(($event.target as HTMLInputElement).value))" /></label>
      <div class="row">
        <button type="button" :class="{ on: state.voice.talking }" @click="toggleVoice">Talking</button>
        <button type="button" @click="cycleVoiceMode">Voice mode</button>
        <button type="button" :class="{ on: state.voice.radio }" @click="toggleRadio">Radio</button>
        <button type="button" :class="{ on: state.staminaActive }" @click="toggleStamina">Stamina</button>
        <button type="button" :class="{ on: state.oxygenActive }" @click="toggleOxygen">Oxygen</button>
        <button type="button" :class="{ on: Boolean(state.weapon?.show) }" @click="toggleWeapon">Weapon</button>
        <button type="button" :class="{ on: state.identity.showMoney }" @click="togglePeek">Peek cash</button>
        <button type="button" :class="{ on: state.vehicle.seatbelt }" @click="toggleBelt">Seatbelt</button>
        <button type="button" :class="{ on: state.vehicle.cruise }" @click="toggleCruise">Cruise</button>
        <button type="button" :class="{ on: state.vehicle.airborne }" @click="toggleAir">Aircraft</button>
        <button type="button" :class="{ on: Boolean(state.compass.waypoint?.active) }" @click="toggleWaypoint">Waypoint</button>
      </div>
    </div>
  </aside>
</template>
