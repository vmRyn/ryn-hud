<script setup lang="ts">
import { computed } from 'vue'
import type { HudState, SpeedStyle, Theme } from '../types'
import HudIcon from './HudIcon.vue'

const props = defineProps<{
  active: boolean
  mapVisible?: boolean
  state: HudState
  theme: Theme
  preview?: boolean
}>()

const ANALOG_START = 135
const ANALOG_SWEEP = 270
const ANALOG_CX = 60
const ANALOG_CY = 56

const style = computed<SpeedStyle>(() => props.theme.vehicle.speedStyle || 'digitalArc')
const units = computed(() => (props.theme.vehicle.units === 'kph' ? 'kph' : 'mph'))
const maxSpeed = computed(() => (units.value === 'kph' ? 260 : 160))
const speedValue = computed(() => Math.max(0, props.state.vehicle.speed))
const speedText = computed(() => String(Math.round(speedValue.value)).padStart(3, '0'))
const firstDigit = computed(() => {
  const idx = speedText.value.split('').findIndex((d) => d !== '0')
  return idx === -1 ? 2 : idx
})
const altitude = computed(() => String(Math.max(0, Math.round(props.state.vehicle.altitude))))
const rpmPct = computed(() => Math.max(0, Math.min(100, props.state.vehicle.rpm)))
const speedPct = computed(() => Math.max(0, Math.min(1, speedValue.value / maxSpeed.value)))
const airborne = computed(() => props.state.vehicle.airborne)
const isMinimal = computed(() => style.value === 'minimal')
const isAnalog = computed(() => style.value === 'analog')
const isCircular = computed(() => style.value === 'circular')
const isDigitalFamily = computed(() => style.value === 'digital' || style.value === 'digitalArc')
const showRpmBar = computed(() => style.value === 'digitalArc' && !airborne.value)
const showMeta = computed(() => !isMinimal.value)
const usePanel = computed(() => props.theme.vehicle.readoutBackground !== false)

function polar(radius: number, deg: number) {
  const rad = (deg * Math.PI) / 180
  return {
    x: ANALOG_CX + radius * Math.cos(rad),
    y: ANALOG_CY + radius * Math.sin(rad),
  }
}

function analogArc(radius: number, startDeg: number, sweepDeg: number) {
  const start = polar(radius, startDeg)
  const end = polar(radius, startDeg + sweepDeg)
  const large = sweepDeg > 180 ? 1 : 0
  return `M ${start.x.toFixed(3)} ${start.y.toFixed(3)} A ${radius} ${radius} 0 ${large} 1 ${end.x.toFixed(3)} ${end.y.toFixed(3)}`
}

const analogHot = computed(() => !airborne.value && speedPct.value >= 0.82)
const analogNeedle = computed(() => ANALOG_START + 90 + speedPct.value * ANALOG_SWEEP)
const analogTrack = computed(() => analogArc(51.2, ANALOG_START, ANALOG_SWEEP))
const analogSpeedArc = computed(() => analogArc(51.2, ANALOG_START, Math.max(0.7, speedPct.value * ANALOG_SWEEP)))
const analogRedline = computed(() => analogArc(51.2, ANALOG_START + ANALOG_SWEEP * 0.82, ANALOG_SWEEP * 0.18))
const analogRpmTrack = computed(() => analogArc(29.4, ANALOG_START, ANALOG_SWEEP))
const analogRpmArc = computed(() =>
  analogArc(29.4, ANALOG_START, Math.max(1.4, (rpmPct.value / 100) * ANALOG_SWEEP)),
)

const analogMarks = computed(() => {
  const max = maxSpeed.value
  const majorEvery = units.value === 'kph' ? 40 : 20
  const minorEvery = units.value === 'kph' ? 20 : 10
  const microEvery = units.value === 'kph' ? 10 : 5
  const marks: {
    v: number
    kind: 'micro' | 'minor' | 'major'
    hot: boolean
    x1: number
    y1: number
    x2: number
    y2: number
    labelX: number
    labelY: number
  }[] = []
  for (let v = 0; v <= max; v += microEvery) {
    const deg = ANALOG_START + (v / max) * ANALOG_SWEEP
    const major = v % majorEvery === 0 || v === max
    const minor = !major && v % minorEvery === 0
    const kind = major ? 'major' : minor ? 'minor' : 'micro'
    const outer = polar(48.8, deg)
    const inner = polar(major ? 43.6 : minor ? 45.6 : 46.8, deg)
    const label = polar(39.6, deg)
    marks.push({
      v,
      kind,
      hot: v / max >= 0.82,
      x1: inner.x,
      y1: inner.y,
      x2: outer.x,
      y2: outer.y,
      labelX: label.x,
      labelY: label.y,
    })
  }
  return marks
})

const analogLabels = computed(() => analogMarks.value.filter((mark) => mark.kind === 'major'))

const circularFill = computed(() => `${(speedPct.value * 75).toFixed(2)} 100`)
const circularRpmFill = computed(() => `${((rpmPct.value / 100) * 75).toFixed(2)} 100`)
</script>

<template>
  <div class="vehicle-scene" :class="{ 'is-on': active, 'is-map': mapVisible && !active }">
    <div class="vehicle-cluster">
      <div
        class="map-frame"
        :class="{
          'is-mock': preview,
          'is-circle': theme.vehicle.minimapShape === 'circle',
        }"
      />
      <div
        class="readout"
        :class="[
          `style-${style}`,
          {
            'has-bg': usePanel && !isAnalog,
            'is-gauge': isAnalog || isCircular,
          },
        ]"
      >
        <div class="readout-body">
          <div v-if="isDigitalFamily || isMinimal" class="speed-line" :class="{ compact: isMinimal }">
            <template v-if="airborne">
              <strong>{{ altitude }}</strong>
              <em>alt</em>
            </template>
            <template v-else>
              <strong>
                <span
                  v-for="(digit, index) in speedText.split('')"
                  :key="index"
                  :class="{ dim: index < firstDigit }"
                >{{ digit }}</span>
              </strong>
              <em>{{ units }}</em>
            </template>
          </div>

          <div v-if="isAnalog" class="speedo-analog" :class="{ hot: analogHot }" aria-hidden="true">
            <svg viewBox="0 0 120 128">
              <defs>
                <radialGradient id="analog-face" cx="38%" cy="32%" r="68%">
                  <stop offset="0%" stop-color="color-mix(in srgb, var(--text) 7%, transparent)" />
                  <stop offset="72%" stop-color="color-mix(in srgb, var(--surface-strong) 72%, transparent)" />
                  <stop offset="100%" stop-color="color-mix(in srgb, #000 55%, transparent)" />
                </radialGradient>
              </defs>
              <circle class="analog-face" cx="60" cy="56" r="54" />
              <circle class="analog-bezel" cx="60" cy="56" r="54" />
              <path class="analog-track" :d="analogTrack" />
              <path class="analog-redline" :d="analogRedline" />
              <path
                v-if="!airborne && speedPct > 0.004"
                class="analog-progress"
                :d="analogSpeedArc"
              />
              <line
                v-for="mark in analogMarks"
                :key="mark.v"
                class="analog-tick"
                :class="[mark.kind, { hot: mark.hot }]"
                :x1="mark.x1"
                :y1="mark.y1"
                :x2="mark.x2"
                :y2="mark.y2"
              />
              <text
                v-for="mark in analogLabels"
                :key="`l-${mark.v}`"
                class="analog-label"
                :class="{ hot: mark.hot }"
                :x="mark.labelX"
                :y="mark.labelY"
                text-anchor="middle"
                dominant-baseline="middle"
              >{{ mark.v }}</text>
              <g v-if="!airborne">
                <path class="analog-rpm-track" :d="analogRpmTrack" />
                <path v-if="rpmPct > 2" class="analog-rpm" :d="analogRpmArc" />
              </g>
              <g class="analog-needle" :transform="`rotate(${analogNeedle} 60 56)`">
                <path
                  class="analog-needle-body"
                  d="M59.58 56.2 L59.86 19.4 L60 11.6 L60.14 19.4 L60.42 56.2 L60.95 63.6 A 1.05 1.05 0 1 1 59.05 63.6 Z"
                />
                <circle class="analog-hub-ring" cx="60" cy="56" r="3.7" />
                <circle class="analog-hub" cx="60" cy="56" r="2.15" />
              </g>
              <text class="analog-speed" x="60" y="116.2" text-anchor="middle">
                {{ airborne ? altitude : Math.round(speedValue) }}
              </text>
              <text class="analog-units" x="60" y="124.6" text-anchor="middle">
                {{ airborne ? 'alt' : units }}
              </text>
            </svg>
          </div>

          <div v-if="isCircular" class="speedo-circular" aria-hidden="true">
            <svg viewBox="0 0 36 36">
              <g transform="rotate(135 18 18)">
                <circle class="circ-track" cx="18" cy="18" r="14.4" pathLength="100" />
                <circle
                  class="circ-value"
                  cx="18"
                  cy="18"
                  r="14.4"
                  pathLength="100"
                  :stroke-dasharray="circularFill"
                />
                <circle
                  class="circ-rpm-track"
                  cx="18"
                  cy="18"
                  r="11.2"
                  pathLength="100"
                />
                <circle
                  v-if="!airborne"
                  class="circ-rpm"
                  cx="18"
                  cy="18"
                  r="11.2"
                  pathLength="100"
                  :stroke-dasharray="circularRpmFill"
                />
              </g>
            </svg>
            <div class="circ-face">
              <strong>{{ airborne ? altitude : Math.round(speedValue) }}</strong>
              <em>{{ airborne ? 'alt' : units }}</em>
            </div>
          </div>

          <div v-if="showRpmBar" class="rpm">
            <i :style="{ width: `${rpmPct}%` }" />
          </div>

          <div v-if="showMeta" class="meta">
            <span v-if="theme.vehicle.showGear && !airborne" class="gear">{{ state.vehicle.gear }}</span>
            <span v-if="theme.vehicle.showFuel" class="v-stat">
              <HudIcon :name="theme.icons.fuel" :badge-style="theme.badgeStyle" />
              <i class="tick"><b :style="{ width: `${state.vehicle.fuel}%` }" /></i>
            </span>
            <span v-if="theme.vehicle.showEngine" class="v-stat">
              <em>eng</em>
              <i class="tick"><b :style="{ width: `${state.vehicle.engine}%` }" /></i>
            </span>
            <span
              v-if="theme.vehicle.showCruise !== false && state.vehicle.cruise"
              class="cruise"
            >cruise</span>
            <span
              v-if="state.vehicle.seatbeltVisible && !state.vehicle.seatbelt"
              class="belt"
            >belt</span>
          </div>
          <span
            v-else-if="state.vehicle.seatbeltVisible && !state.vehicle.seatbelt"
            class="belt"
          >belt</span>
        </div>
      </div>
    </div>
  </div>
</template>
