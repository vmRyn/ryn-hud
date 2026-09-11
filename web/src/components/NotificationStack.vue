<script setup lang="ts">
import { computed, onUnmounted, watch } from 'vue'
import HudIcon from './HudIcon.vue'
import type { HudNotification, NotifyConfig, NotifyType, Theme } from '../types'

const props = defineProps<{
  items: HudNotification[]
  config: NotifyConfig
  theme: Theme
  shiftForIdentity?: boolean
}>()

const emit = defineEmits<{
  dismiss: [id: string]
}>()

const timers = new Map<string, number>()

const DEFAULT_ICONS: Record<NotifyType, string> = {
  info: 'info',
  success: 'check',
  warning: 'warning',
  error: 'x',
  announce: 'megaphone',
}

const visibleItems = computed(() => props.items.slice(0, Math.max(1, props.config.maxVisible)))

const stackStyle = computed(() => ({
  '--notify-ox': `${props.config.offsetX}vh`,
  '--notify-oy': `${props.config.offsetY}vh`,
}))

function iconFor(item: HudNotification) {
  return item.icon || DEFAULT_ICONS[item.type] || 'info'
}

function accentFor(item: HudNotification) {
  if (item.color) return item.color
  if (item.type === 'success') return props.theme.colors.armor
  if (item.type === 'warning') return props.theme.warning
  if (item.type === 'error') return props.theme.critical
  if (item.type === 'announce') return props.theme.accent
  return props.theme.accent
}

function schedule(item: HudNotification) {
  if (timers.has(item.id)) return
  const handle = window.setTimeout(() => {
    timers.delete(item.id)
    emit('dismiss', item.id)
  }, Math.max(1200, item.duration || 5000))
  timers.set(item.id, handle)
}

watch(
  () => props.items.map((item) => item.id).join('|'),
  () => {
    const live = new Set(props.items.map((item) => item.id))
    for (const [id, handle] of timers) {
      if (!live.has(id)) {
        window.clearTimeout(handle)
        timers.delete(id)
      }
    }
    for (const item of props.items) {
      schedule(item)
    }
  },
  { immediate: true },
)

onUnmounted(() => {
  for (const handle of timers.values()) window.clearTimeout(handle)
  timers.clear()
})
</script>

<template>
  <div
    v-if="config.enabled"
    class="notify-stack"
    :class="[
      config.position,
      {
        'is-bottom': config.position.startsWith('bottom'),
        'shift-identity': shiftForIdentity && config.position === 'top-right',
      },
    ]"
    :style="stackStyle"
  >
    <TransitionGroup :name="config.position.startsWith('bottom') ? 'notify-up' : 'notify'" tag="div" class="notify-list">
      <article
        v-for="item in visibleItems"
        :key="item.id"
        class="notify-card"
        :class="[`is-${item.type}`]"
        :style="{ '--notify-accent': accentFor(item) }"
      >
        <span class="notify-accent" aria-hidden="true" />
        <span class="notify-icon">
          <HudIcon :name="iconFor(item)" badge-style="filled" />
        </span>
        <div class="notify-body">
          <strong v-if="item.title" class="notify-title">{{ item.title }}</strong>
          <p class="notify-message">{{ item.message }}</p>
        </div>
      </article>
    </TransitionGroup>
  </div>
</template>
