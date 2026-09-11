<script setup lang="ts">
import { computed, onMounted, onUnmounted, reactive, ref, watch } from 'vue'
import StatusCluster from './components/StatusCluster.vue'
import VehicleScene from './components/VehicleScene.vue'
import CompassBar from './components/CompassBar.vue'
import IdentityChips from './components/IdentityChips.vue'
import NotificationStack from './components/NotificationStack.vue'
import ProgressBar from './components/ProgressBar.vue'
import CinematicBars from './components/CinematicBars.vue'
import AdminPanel from './components/admin/AdminPanel.vue'
import DevTools from './components/dev/DevTools.vue'
import {
  applyThemeVars,
  defaultNotifyConfig,
  defaultState,
  defaultTheme,
  idleProgress,
  mergeTheme,
  type HudNotification,
  type HudState,
  type MinimapShape,
  type NotifyConfig,
  type NotifyType,
  type ProgressState,
  type SpeedStyle,
  type Theme,
} from './types'
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
const notifyConfig = ref<NotifyConfig>({ ...defaultNotifyConfig })
const notifications = ref<HudNotification[]>([])
let notifySeq = 0
const progress = ref<ProgressState>({ ...idleProgress })
let progressSeq = 0
let previewProgressTimer: number | null = null
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

const identityPeeking = computed(
  () => Boolean(state.identity.showMoney || state.identity.showJob),
)

const statusBottomCenter = computed(() => theme.value.status.position === 'bottom-center')

function clearPreviewProgressTimer() {
  if (previewProgressTimer) {
    window.clearTimeout(previewProgressTimer)
    previewProgressTimer = null
  }
}

function hideProgress() {
  clearPreviewProgressTimer()
  progress.value = { ...idleProgress }
}

function showProgress(raw: Partial<ProgressState> & { label?: string; duration?: number | null }) {
  const label = String(raw.label || 'Please wait…').trim() || 'Please wait…'
  progressSeq += 1
  const id = raw.id || `progress-${Date.now()}-${progressSeq}`
  const duration =
    typeof raw.duration === 'number' && raw.duration > 0 ? Math.round(raw.duration) : null
  const value = typeof raw.value === 'number' ? Math.min(100, Math.max(0, raw.value)) : duration ? 0 : 0
  clearPreviewProgressTimer()
  progress.value = {
    active: true,
    id,
    label,
    value,
    duration,
    icon: raw.icon || null,
    color: raw.color || null,
    canCancel: raw.canCancel === true,
  }
  if (preview && duration) {
    previewProgressTimer = window.setTimeout(() => {
      hideProgress()
    }, duration + 80)
  }
}

function updateProgress(raw: Partial<ProgressState> & { value?: number; label?: string }) {
  if (!progress.value.active) return
  const next = { ...progress.value }
  if (typeof raw.value === 'number') {
    next.value = Math.min(100, Math.max(0, raw.value))
  }
  if (typeof raw.label === 'string' && raw.label.trim()) {
    next.label = raw.label.trim()
  }
  next.duration = null
  progress.value = next
  if (next.value >= 100) {
    window.setTimeout(() => hideProgress(), 180)
  }
}

function pushNotification(raw: Partial<HudNotification> & { message?: string }) {
  if (!notifyConfig.value.enabled) return
  const message = String(raw.message || '').trim()
  if (!message) return
  notifySeq += 1
  const id = raw.id || `preview-${Date.now()}-${notifySeq}`
  const type = (raw.type || 'info') as NotifyType
  const next: HudNotification = {
    id,
    title: raw.title || null,
    message,
    type,
    duration: typeof raw.duration === 'number' ? raw.duration : type === 'item' ? 3200 : 5000,
    icon: raw.icon || null,
    color: raw.color || null,
    count: typeof raw.count === 'number' ? raw.count : null,
  }
  notifications.value = [next, ...notifications.value.filter((item) => item.id !== id)].slice(
    0,
    Math.max(1, notifyConfig.value.maxVisible + 2),
  )
  if (notifyConfig.value.sound !== false) {
    playHudSound('notify', notifyConfig.value.soundVolume ?? 0.4)
  }
}

function dismissNotification(id: string) {
  notifications.value = notifications.value.filter((item) => item.id !== id)
}

function clearAllNotifications() {
  notifications.value = []
}

function setNotifyConfig(data: Partial<NotifyConfig> | null | undefined) {
  if (!data || typeof data !== 'object') return
  notifyConfig.value = {
    enabled: data.enabled !== false,
    position:
      data.position === 'top-left' ||
      data.position === 'top-right' ||
      data.position === 'bottom-left' ||
      data.position === 'bottom-right'
        ? data.position
        : notifyConfig.value.position,
    offsetX: Number.isFinite(Number(data.offsetX)) ? Number(data.offsetX) : notifyConfig.value.offsetX,
    offsetY: Number.isFinite(Number(data.offsetY)) ? Number(data.offsetY) : notifyConfig.value.offsetY,
    maxVisible: Math.min(8, Math.max(1, Math.round(Number(data.maxVisible) || notifyConfig.value.maxVisible))),
    sound: data.sound !== false,
    soundVolume: Number.isFinite(Number(data.soundVolume))
      ? Math.min(1, Math.max(0, Number(data.soundVolume)))
      : notifyConfig.value.soundVolume,
  }
}

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
    return
  }
  if (action === 'setNotifyConfig') {
    setNotifyConfig(data)
    return
  }
  if (action === 'notify') {
    pushNotification(data || {})
    return
  }
  if (action === 'clearNotifications') {
    clearAllNotifications()
    return
  }
  if (action === 'progressShow') {
    showProgress(data || {})
    return
  }
  if (action === 'progressUpdate') {
    updateProgress(data || {})
    return
  }
  if (action === 'progressHide') {
    hideProgress()
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
  clearPreviewProgressTimer()
})
</script>

<template>
  <div v-if="visible || cinematic" class="hud-root" :class="{ 'is-preview': preview, 'is-cinematic': cinematic }">
    <CinematicBars :active="cinematic" />
    <div v-show="hudVisible && !cinematic" class="hud-stage">
      <CompassBar :visible="theme.visibility.compass" :state="state" :theme="theme" />
      <IdentityChips :state="state" :theme="theme" />
      <NotificationStack
        :items="notifications"
        :config="notifyConfig"
        :theme="theme"
        :shift-for-identity="identityPeeking && theme.identity.position === 'top-right'"
        @dismiss="dismissNotification"
      />
      <div v-if="!statusBottomCenter" class="progress-anchor">
        <ProgressBar :progress="progress" :theme="theme" />
      </div>
      <div
        class="dock"
        :class="[
          theme.status.position,
          {
            'is-vehicle': vehicleScene || liftStatusForMap,
            'has-progress': statusBottomCenter && progress.active,
          },
        ]"
      >
        <ProgressBar
          v-if="statusBottomCenter"
          :progress="progress"
          :theme="theme"
          stacked
        />
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
      :progress-active="progress.active"
      @patch="patchState"
      @vehicle="vehicleScene = $event"
      @admin="adminOpen = $event"
      @scenario="applyScenario"
      @cinematic="cinematic = $event"
      @hud-visible="hudVisible = $event"
      @speed-style="setSpeedStyle"
      @minimap-shape="setMinimapShape"
      @notify="pushNotification"
      @clear-notifications="clearAllNotifications"
      @progress-start="showProgress"
      @progress-update="updateProgress"
      @progress-cancel="hideProgress"
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
