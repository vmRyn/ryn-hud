<script setup lang="ts">
import { nextTick, onBeforeUnmount, ref, watch } from 'vue'

const props = defineProps<{
  active: boolean
}>()

const mounted = ref(false)
const visible = ref(false)

const DURATION_MS = 780

let leaveTimer: number | null = null

watch(
  () => props.active,
  async (active) => {
    if (leaveTimer) {
      window.clearTimeout(leaveTimer)
      leaveTimer = null
    }

    if (active) {
      mounted.value = true
      visible.value = false
      await nextTick()
      requestAnimationFrame(() => {
        requestAnimationFrame(() => {
          visible.value = true
        })
      })
      return
    }

    visible.value = false
    leaveTimer = window.setTimeout(() => {
      if (!props.active) {
        mounted.value = false
      }
    }, DURATION_MS)
  },
  { immediate: true },
)

onBeforeUnmount(() => {
  if (leaveTimer) {
    window.clearTimeout(leaveTimer)
  }
})
</script>

<template>
  <div v-if="mounted" class="cinematic-bars" :class="{ 'is-visible': visible }" aria-hidden="true">
    <i class="bar top" />
    <i class="bar bottom" />
  </div>
</template>
