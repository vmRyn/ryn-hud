<script setup lang="ts">
import { computed, onMounted, onUnmounted, reactive, ref, watch } from 'vue'
import StatusCluster from './components/StatusCluster.vue'
import VehicleScene from './components/VehicleScene.vue'
import CompassBar from './components/CompassBar.vue'
import IdentityChips from './components/IdentityChips.vue'
import CinematicBars from './components/CinematicBars.vue'
import AdminPanel from './components/admin/AdminPanel.vue'
import DevTools from './components/dev/DevTools.vue'
import { applyThemeVars, defaultState, defaultTheme, mergeTheme, type HudState, type MinimapShape, type SpeedStyle, type Theme } from './types'
import { isBrowserPreview, nuiPost, setBrowserNuiHandler } from './nui'
import { THEME_STORAGE_KEY, createMockState, mockScenarios, PREVIEW_BACKGROUND_URL } from './preview'
import { playHudSound } from './sounds'

const preview = isBrowserPreview()
const visible = ref(false)
const hudVisible = ref(true)
const cinematic = ref(false)
const cinematicBarHeight = ref(11)
const adminOpen = ref(false)
const vehicleScene = ref(false)
const showDevTools = ref(true)
const theme = ref<Theme>(mergeTheme(defaultTheme, {}))
const state = reactive<HudState>(
  JSON.parse(JSON.stringify(preview ? createMockState() : defaultState)) as HudState,
)
const adminRef = ref<{ sync: (theme: Theme) => void } | null>(null)

applyThemeVars(theme.value)
document.documentElement.style.setProperty('--cinematic-bar-height', `${cinematicBarHeight.value}vh`)

watch(
  () => state.vehicle.seatbelt,
  (on, prev) => {
    if (!preview || typeof prev !== 'boolean') return
    playHudSound(on ? 'seatbeltOn' : 'seatbeltOff')
  },
)

const mapVisible = computed(
  () =>
    vehicleScene.value ||
    (theme.value.vehicle.minimapShape === 'circle' && theme.value.visibility.radarOnFoot && hudVisible.value && !cinematic.value),
)

const liftStatusForMap = computed(
  () =>
    theme.value.vehicle.minimapShape === 'circle' &&
    theme.value.status.position === 'bottom-left' &&
    mapVisible.value,
)

function patchState(patch: Partial<HudState>) {
  for (const [key, value] of Object.entries(patch)) {
    const k = key as keyof HudState
    const current = state[k]
    if (value && typeof value === 'object' && !Array.isArray(value) && current && typeof current === 'object') {
      Object.assign(current as object, value)
    } else {
      ;(state as Record<string, unknown>)[key] = value
    }
  }
}

function setTheme(next: Theme | Partial<Theme>) {
  theme.value = mergeTheme(defaultTheme, next as Theme)
  applyThemeVars(theme.value)
  adminRef.value?.sync(theme.value)
}

function setMinimapShape(next: MinimapShape) {
  setTheme({
    ...theme.value,
    vehicle: {
      ...theme.value.vehicle,
      minimapShape: next,
    },
  })
}

function setSpeedStyle(next: SpeedStyle) {
  setTheme({
    ...theme.value,
    vehicle: {
      ...theme.value.vehicle,
      speedStyle: next,
    },
  })
}

function onMessage(event: MessageEvent) {
  const payload = event.data
  if (!payload || typeof payload !== 'object') return
  const action = payload.action as string
  const data = payload.data
  if (action === 'setVisible') {
    visible.value = Boolean(data)
    return
  }
  if (action === 'setHudVisible') {
    hudVisible.value = data?.visible !== false
    return
  }
  if (action === 'setCinematic') {
    cinematic.value = Boolean(data?.active)
    if (typeof data?.barHeight === 'number') {
      cinematicBarHeight.value = data.barHeight
    }
    document.documentElement.style.setProperty(
      '--cinematic-bar-height',
      `${cinematicBarHeight.value}vh`,
    )
    if (cinematic.value) {
      adminOpen.value = false
    }
    return
  }
  if (action === 'patchState' || action === 'setState') {
    patchState(data || {})
    return
  }
  if (action === 'setTheme') {
    setTheme(data)
    return
  }
  if (action === 'setVehicleScene') {
    vehicleScene.value = Boolean(data?.active)
    return
  }
  if (action === 'openAdmin') {
    adminOpen.value = true
    if (data?.theme) setTheme(data.theme)
    return
  }
  if (action === 'closeAdmin') {
    adminOpen.value = false
    return
  }
  if (action === 'playSound' && data?.id) {
    playHudSound(String(data.id), typeof data.volume === 'number' ? data.volume : 0.45)
  }
}

function onKey(event: KeyboardEvent) {
  if (event.key === 'Escape' && adminOpen.value) {
    nuiPost('closeAdmin')
  }
  if (preview && event.key === '`' && !event.repeat) {
    showDevTools.value = !showDevTools.value
  }
}

function previewTheme(next: Theme) {
  setTheme(next)
  nuiPost('previewTheme', { theme: next })
}

function applyScenario(name: string) {
  const patch = mockScenarios[name]
  if (patch) patchState(patch)
}

function startPreview() {
  document.documentElement.classList.add('is-preview')
  document.body.classList.add('is-preview')
  document.documentElement.style.setProperty('--preview-bg', `url("${PREVIEW_BACKGROUND_URL}")`)
  visible.value = true
  vehicleScene.value = false

  const saved = localStorage.getItem(THEME_STORAGE_KEY)
  if (saved) {
    try {
      setTheme(JSON.parse(saved) as Theme)
    } catch {
      setTheme(defaultTheme)
    }
  }

  setBrowserNuiHandler((event, data) => {
    if (event === 'closeAdmin') adminOpen.value = false
    if (event === 'previewTheme') {
      const payload = data as { theme?: Theme }
      if (payload?.theme) setTheme(payload.theme)
    }
    if (event === 'saveTheme') {
      const payload = data as { theme?: Theme }
      if (payload?.theme) {
        setTheme(payload.theme)
        localStorage.setItem(THEME_STORAGE_KEY, JSON.stringify(theme.value))
      }
    }
    if (event === 'resetTheme') {
      localStorage.removeItem(THEME_STORAGE_KEY)
      setTheme(defaultTheme)
    }
    return { ok: true }
  })
}

onMounted(() => {
  window.addEventListener('message', onMessage)
  window.addEventListener('keydown', onKey)
  if (preview) {
    startPreview()
    return
  }
  nuiPost('nuiReady')
})

onUnmounted(() => {
  window.removeEventListener('message', onMessage)
  window.removeEventListener('keydown', onKey)
  setBrowserNuiHandler(null)
})
</script>

<template>
  <div v-if="visible || cinematic" class="hud-root" :class="{ 'is-preview': preview, 'is-cinematic': cinematic }">
    <CinematicBars :active="cinematic" />
    <div v-show="hudVisible && !cinematic" class="hud-stage">
      <CompassBar :visible="theme.visibility.compass" :state="state" :theme="theme" />
      <IdentityChips :state="state" :theme="theme" />
      <div
        class="dock"
        :class="[
          theme.status.position,
          { 'is-vehicle': vehicleScene || liftStatusForMap },
        ]"
      >
        <StatusCluster :state="state" :theme="theme" />
      </div>
      <VehicleScene
        :active="vehicleScene"
        :map-visible="mapVisible"
        :state="state"
        :theme="theme"
        :preview="preview"
      />
    </div>
    <AdminPanel v-if="adminOpen && hudVisible && !cinematic" ref="adminRef" :theme="theme" @preview="previewTheme" />
    <DevTools
      v-if="preview && showDevTools"
      :state="state"
      :vehicle-scene="vehicleScene"
      :admin-open="adminOpen"
      :cinematic="cinematic"
      :hud-visible="hudVisible"
      :speed-style="theme.vehicle.speedStyle"
      :minimap-shape="theme.vehicle.minimapShape"
      @patch="patchState"
      @vehicle="vehicleScene = $event"
      @admin="adminOpen = $event"
      @scenario="applyScenario"
      @cinematic="cinematic = $event"
      @hud-visible="hudVisible = $event"
      @speed-style="setSpeedStyle"
      @minimap-shape="setMinimapShape"
    />
    <button
      v-else-if="preview"
      class="devtools-fab"
      type="button"
      @click="showDevTools = true"
    >
      Dev tools
    </button>
  </div>
</template>
