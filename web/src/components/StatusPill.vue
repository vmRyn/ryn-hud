<script setup lang="ts">
import { computed } from 'vue'
import HudIcon from './HudIcon.vue'
import type { BadgeLayout, BadgeShape, BadgeStyle } from '../types'

const props = defineProps<{
  value: number
  icon: string
  color: string
  layout: BadgeLayout
  shape: BadgeShape
  badgeStyle: BadgeStyle
  ringBackground?: boolean
  hurt?: boolean
}>()

const clamped = computed(() => Math.max(0, Math.min(100, Math.round(props.value || 0))))
const offset = computed(() => 100 - clamped.value)
const showRingBg = computed(() => props.layout === 'ring' && props.ringBackground === true)
const roundedRing =
  'M18 3H25A8 8 0 0 1 33 11V25A8 8 0 0 1 25 33H11A8 8 0 0 1 3 25V11A8 8 0 0 1 11 3H18'
</script>

<template>
  <div
    class="stat"
    :class="[`layout-${layout}`, `shape-${shape}`, { 'ring-bg': showRingBg, 'is-hurt': hurt }]"
    :style="{ '--c': color, '--p': `${clamped}%` }"
  >
    <svg
      v-if="layout === 'ring'"
      class="stat-ring"
      :class="{ 'from-top': shape === 'rounded' }"
      viewBox="0 0 36 36"
      aria-hidden="true"
    >
      <circle
        v-if="shape === 'circle'"
        class="track"
        cx="18"
        cy="18"
        r="15.2"
        pathLength="100"
      />
      <circle
        v-if="shape === 'circle'"
        class="value"
        cx="18"
        cy="18"
        r="15.2"
        pathLength="100"
        stroke-dasharray="100"
        :stroke-dashoffset="offset"
      />
      <path v-if="shape === 'rounded'" class="track" :d="roundedRing" pathLength="100" />
      <path
        v-if="shape === 'rounded'"
        class="value"
        :d="roundedRing"
        pathLength="100"
        stroke-dasharray="100"
        :stroke-dashoffset="offset"
      />
    </svg>
    <span v-if="layout === 'fill'" class="stat-fill"><i /></span>
    <div class="stat-face">
      <HudIcon :name="icon" :badge-style="badgeStyle" />
      <b v-if="layout === 'percent'">{{ clamped }}%</b>
    </div>
    <span v-if="layout === 'bars'" class="stat-bar"><i /></span>
  </div>
</template>
