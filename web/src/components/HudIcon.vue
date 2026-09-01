<script setup lang="ts">
import { computed } from 'vue'
import type { BadgeStyle } from '../types'
import { iconComponent } from '../icons'

const props = defineProps<{
  name: string
  badgeStyle?: BadgeStyle
}>()

const icon = computed(() => iconComponent(props.name))
const weight = computed(() => {
  if (props.badgeStyle === 'filled') return 'fill'
  if (props.badgeStyle === 'outline') return 'regular'
  return 'duotone'
})
</script>

<template>
  <span class="hud-icon" aria-hidden="true">
    <component :is="icon" :weight="weight" color="currentColor" />
  </span>
</template>
