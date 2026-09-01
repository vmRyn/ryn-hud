<script setup lang="ts">
import { computed } from 'vue'
import {
  shouldShowCoreStat,
  themeVisible,
  voiceModeLabel,
  type HudState,
  type Theme,
} from '../types'
import AmmoChip from './AmmoChip.vue'
import StatusPill from './StatusPill.vue'

const props = defineProps<{
  state: HudState
  theme: Theme
}>()

const layout = computed(() => props.theme.badgeLayout || 'ring')
const shape = computed(() => props.theme.badgeShape || 'circle')
const showVoiceLabel = computed(
  () =>
    themeVisible(props.theme, 'voiceModeLabel') &&
    props.state.voice.talking &&
    !props.state.voice.radio,
)

function color(key: keyof Theme['colors']) {
  return props.theme.colors?.[key] || props.theme.accent
}

const showAmmo = computed(
  () => themeVisible(props.theme, 'ammo') && !!props.state.weapon?.show && !!props.state.weapon?.hasAmmo,
)
</script>

<template>
  <div class="status-cluster">
    <Transition name="hud-item">
      <AmmoChip
        v-if="showAmmo"
        key="ammo"
        :clip="state.weapon.clip ?? 0"
        :reserve="state.weapon.reserve ?? 0"
        :color="theme.accent"
      />
    </Transition>

    <TransitionGroup
      name="hud-item"
      tag="div"
      class="status-row"
      :class="{ 'is-bars': layout === 'bars' }"
    >
      <StatusPill
        key="health"
        :value="state.health"
        :icon="theme.icons.health"
        :color="color('health')"
        :layout="layout"
        :shape="shape"
        :badge-style="theme.badgeStyle"
        :ring-background="theme.ringBackground"
      />
      <StatusPill
        v-if="shouldShowCoreStat(theme, 'armor', state.armor)"
        key="armor"
        :value="state.armor"
        :icon="theme.icons.armor"
        :color="color('armor')"
        :layout="layout"
        :shape="shape"
        :badge-style="theme.badgeStyle"
        :ring-background="theme.ringBackground"
      />
      <StatusPill
        v-if="shouldShowCoreStat(theme, 'hunger', state.hunger)"
        key="hunger"
        :value="state.hunger"
        :icon="theme.icons.hunger"
        :color="color('hunger')"
        :layout="layout"
        :shape="shape"
        :badge-style="theme.badgeStyle"
        :ring-background="theme.ringBackground"
      />
      <StatusPill
        v-if="shouldShowCoreStat(theme, 'thirst', state.thirst)"
        key="thirst"
        :value="state.thirst"
        :icon="theme.icons.thirst"
        :color="color('thirst')"
        :layout="layout"
        :shape="shape"
        :badge-style="theme.badgeStyle"
        :ring-background="theme.ringBackground"
      />
      <StatusPill
        v-if="theme.visibility.stress && state.stress != null"
        key="stress"
        :value="state.stress"
        :icon="theme.icons.stress"
        :color="color('stress')"
        :layout="layout"
        :shape="shape"
        :badge-style="theme.badgeStyle"
        :ring-background="theme.ringBackground"
      />
      <div
        v-if="themeVisible(theme, 'voice') && (state.voice.talking || state.voice.radio)"
        key="voice-wrap"
        class="voice-stat"
      >
        <StatusPill
          key="voice"
          :value="state.voice.talking ? 100 : 64"
          :icon="theme.icons.voice"
          :color="color('voice')"
          :layout="layout"
          :shape="shape"
          :badge-style="theme.badgeStyle"
          :ring-background="theme.ringBackground"
        />
        <span v-if="showVoiceLabel" class="voice-mode">{{ voiceModeLabel(state.voice.mode) }}</span>
        <span v-else-if="state.voice.radio" class="voice-mode">RADIO</span>
      </div>
      <StatusPill
        v-if="themeVisible(theme, 'stamina') && state.staminaActive"
        key="stamina"
        :value="state.stamina"
        :icon="theme.icons.stamina"
        :color="color('stamina')"
        :layout="layout"
        :shape="shape"
        :badge-style="theme.badgeStyle"
        :ring-background="theme.ringBackground"
      />
      <StatusPill
        v-if="themeVisible(theme, 'oxygen') && state.oxygenActive"
        key="oxygen"
        :value="state.oxygen"
        :icon="theme.icons.oxygen"
        :color="color('oxygen')"
        :layout="layout"
        :shape="shape"
        :badge-style="theme.badgeStyle"
        :ring-background="theme.ringBackground"
      />
      <StatusPill
        v-if="themeVisible(theme, 'parachute') && state.parachute"
        key="parachute"
        :value="100"
        icon="parachute"
        :color="color('stamina')"
        :layout="layout"
        :shape="shape"
        :badge-style="theme.badgeStyle"
        :ring-background="theme.ringBackground"
      />
      <StatusPill
        v-if="themeVisible(theme, 'harness') && state.harness"
        key="harness"
        :value="100"
        icon="shield"
        :color="color('armor')"
        :layout="layout"
        :shape="shape"
        :badge-style="theme.badgeStyle"
        :ring-background="theme.ringBackground"
      />
    </TransitionGroup>
  </div>
</template>
