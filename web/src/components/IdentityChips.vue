<script setup lang="ts">
import type { HudState, Theme } from '../types'

const props = defineProps<{
  state: HudState
  theme: Theme
}>()

function money(value: number) {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    maximumFractionDigits: 0,
  }).format(value || 0)
}

function visible() {
  return props.state.identity.showMoney || props.state.identity.showJob
}
</script>

<template>
  <div class="identity hud-anchor" :class="theme.identity.position">
    <Transition name="hud-panel">
      <div v-if="visible()" key="identity" class="identity-panel">
        <TransitionGroup name="hud-item" tag="div" class="identity-chips">
          <div v-if="state.identity.showJob && state.identity.job" key="job" class="chip">
            {{ state.identity.job }}
          </div>
          <div v-if="state.identity.showMoney" key="cash" class="chip">
            {{ money(state.identity.cash) }}
          </div>
          <div v-if="state.identity.showMoney" key="bank" class="chip">
            {{ money(state.identity.bank) }}
          </div>
        </TransitionGroup>
      </div>
    </Transition>
  </div>
</template>
