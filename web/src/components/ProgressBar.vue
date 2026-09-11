<script setup lang="ts">
import { computed } from 'vue'
import HudIcon from './HudIcon.vue'
import type { ProgressState, Theme } from '../types'

const props = defineProps<{
  progress: ProgressState
  theme: Theme
  stacked?: boolean
}>()

const fillStyle = computed(() => {
  const color = props.progress.color || props.theme.accent
  if (props.progress.duration && props.progress.duration > 0) {
    return {
      '--progress-accent': color,
      '--progress-ms': `${props.progress.duration}ms`,
      width: undefined as string | undefined,
    }
  }
  return {
    '--progress-accent': color,
    width: `${Math.min(100, Math.max(0, props.progress.value))}%`,
  }
})

const showPercent = computed(
  () => !props.progress.duration && props.progress.value > 0,
)
</script>

<template>
  <Transition name="progress-panel">
    <div
      v-if="progress.active"
      :key="progress.id"
      class="progress-bar"
      :class="{ 'is-stacked': stacked, 'is-timed': Boolean(progress.duration) }"
    >
      <div class="progress-meta">
        <span v-if="progress.icon" class="progress-icon">
          <HudIcon :name="progress.icon" badge-style="filled" />
        </span>
        <span class="progress-label">{{ progress.label }}</span>
        <span v-if="showPercent" class="progress-percent">{{ Math.round(progress.value) }}%</span>
        <span v-else-if="progress.canCancel" class="progress-hint">X cancel</span>
      </div>
      <div class="progress-track">
        <i
          :key="`${progress.id}-fill`"
          class="progress-fill"
          :class="{ 'is-timed': Boolean(progress.duration) }"
          :style="fillStyle"
        />
      </div>
    </div>
  </Transition>
</template>
