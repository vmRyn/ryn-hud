<script setup lang="ts">
import HudIcon from './HudIcon.vue'

defineProps<{
  clip: number
  reserve: number
  color: string
}>()
</script>

<template>
  <div class="ammo-chip" :style="{ '--c': color }">
    <HudIcon name="crosshair" badge-style="filled" />
    <span class="ammo-text">
      <b>{{ clip }}</b>
      <i>/</i>
      <span>{{ reserve }}</span>
    </span>
  </div>
</template>
