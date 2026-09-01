<script setup lang="ts">
import { computed } from 'vue'
import { formatWaypointDistance, themeVisible, type HudState, type Theme } from '../types'

const props = defineProps<{
  visible: boolean
  state: HudState
  theme: Theme
}>()

const waypoint = computed(() => {
  if (!themeVisible(props.theme, 'waypoint')) return null
  return props.state.compass.waypoint?.active ? props.state.compass.waypoint : null
})

const streetLine = computed(() => {
  const street = props.state.compass.street
  const crossing = props.state.compass.crossing
  if (street && crossing) return `${street} / ${crossing}`
  return street || crossing || ''
})
</script>

<template>
  <div
    v-if="visible"
    class="compass hud-anchor"
    :class="[theme.compass.position, { 'has-bg': theme.compassBackground !== false }]"
  >
    <b>{{ state.compass.cardinal }}</b>
    <span>{{ streetLine || state.compass.zone }}</span>
    <span v-if="state.compass.zone && streetLine" class="muted">{{ state.compass.zone }}</span>
    <span v-if="waypoint" class="waypoint">
      {{ formatWaypointDistance(waypoint.distance) }}
      <i>{{ waypoint.direction }}</i>
    </span>
  </div>
</template>
