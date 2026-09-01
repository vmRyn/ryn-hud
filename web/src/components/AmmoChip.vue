<script setup lang="ts">
import HudIcon from './HudIcon.vue'

defineProps<{
  clip: number
  reserve: number
  color: string
  label?: string
  fireMode?: string
  hasAmmo?: boolean
}>()
</script>

<template>
  <div class="ammo-chip" :style="{ '--c': color }">
    <HudIcon name="crosshair" badge-style="filled" />
    <span class="ammo-copy">
      <span v-if="label" class="ammo-name">
        {{ label }}<template v-if="fireMode"> · {{ fireMode }}</template>
      </span>
      <span v-if="hasAmmo !== false" class="ammo-text">
        <b>{{ clip }}</b>
        <i>/</i>
        <span>{{ reserve }}</span>
      </span>
    </span>
  </div>
</template>
