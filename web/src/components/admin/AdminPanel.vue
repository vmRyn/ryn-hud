<script setup lang="ts">
import { ref } from 'vue'
import { defaultTheme, mergeTheme, type BadgeLayout, type HudAnchor, type SpeedStyle, type StatusPosition, type Theme } from '../../types'
import { ICON_OPTIONS } from '../../icons'
import { parseColor, toRgba } from '../../themeColor'
import HudIcon from '../HudIcon.vue'
import StatusPill from '../StatusPill.vue'
import { nuiPost } from '../../nui'

const props = defineProps<{
  theme: Theme
}>()

const emit = defineEmits<{
  preview: [theme: Theme]
}>()

const tab = ref<'layout' | 'badges' | 'icons' | 'visibility' | 'vehicle'>('layout')
const draft = ref<Theme>(mergeTheme(defaultTheme, props.theme))
const saved = ref(false)

const layouts: { id: BadgeLayout; label: string }[] = [
  { id: 'ring', label: 'Circle' },
  { id: 'percent', label: 'Percent' },
  { id: 'fill', label: 'Fill' },
  { id: 'bars', label: 'Bars' },
]

const positions: { id: StatusPosition; label: string; slot: string }[] = [
  { id: 'top-left', label: 'Top left', slot: 'tl' },
  { id: 'top-right', label: 'Top right', slot: 'tr' },
  { id: 'bottom-left', label: 'Bottom left', slot: 'bl' },
  { id: 'bottom-center', label: 'Bottom center', slot: 'bc' },
  { id: 'bottom-right', label: 'Bottom right', slot: 'br' },
]

const hudAnchors: { id: HudAnchor; label: string; slot: string }[] = [
  { id: 'top-left', label: 'Top left', slot: 'tl' },
  { id: 'top-center', label: 'Top center', slot: 'tc' },
  { id: 'top-right', label: 'Top right', slot: 'tr' },
  { id: 'bottom-left', label: 'Bottom left', slot: 'bl' },
  { id: 'bottom-center', label: 'Bottom center', slot: 'bc' },
  { id: 'bottom-right', label: 'Bottom right', slot: 'br' },
]

const contextualToggles: {
  key: keyof Theme['visibility']
  label: string
  hint: string
}[] = [
  { key: 'voice', label: 'Voice / radio', hint: 'When talking or on radio' },
  { key: 'voiceModeLabel', label: 'Voice mode label', hint: 'WHISPER / NORMAL / SHOUT while talking' },
  { key: 'stamina', label: 'Stamina', hint: 'While sprinting' },
  { key: 'oxygen', label: 'Oxygen', hint: 'Underwater' },
  { key: 'ammo', label: 'Ammo', hint: 'When holding a gun' },
  { key: 'parachute', label: 'Parachute', hint: 'When chute is equipped' },
  { key: 'harness', label: 'Harness', hint: 'When harness state is active' },
]

const STAT_PALETTES: Record<keyof Theme['colors'], string[]> = {
  health: ['#E06B62', '#C75A52', '#D45B4A', '#E08B82'],
  armor: ['#4CB8A8', '#3AA898', '#6BC4B4', '#7A9E96'],
  hunger: ['#E09440', '#D47A32', '#C9A35A', '#E0B060'],
  thirst: ['#5B97D4', '#4A82C4', '#6AA8D8', '#7A9BB8'],
  stress: ['#A07AD4', '#8B6BC8', '#B08AD8', '#9A6BB0'],
  stamina: ['#C9A85C', '#D4B46A', '#B8944A', '#C4B07A'],
  oxygen: ['#6BB3C2', '#5AA4B4', '#7AC0C8', '#8AA8B0'],
  voice: ['#E4DDD2', '#C9C3B6', '#ECE8E1', '#B8B0A4'],
}

const coreEditors: {
  iconKey: keyof Theme['icons']
  colorKey: keyof Theme['colors']
  label: string
  sample: number
}[] = [
  { iconKey: 'health', colorKey: 'health', label: 'Health', sample: 78 },
  { iconKey: 'armor', colorKey: 'armor', label: 'Armor', sample: 42 },
  { iconKey: 'hunger', colorKey: 'hunger', label: 'Hunger', sample: 71 },
  { iconKey: 'thirst', colorKey: 'thirst', label: 'Thirst', sample: 64 },
  { iconKey: 'stress', colorKey: 'stress', label: 'Stress', sample: 28 },
  { iconKey: 'voice', colorKey: 'voice', label: 'Voice', sample: 100 },
  { iconKey: 'stamina', colorKey: 'stamina', label: 'Stamina', sample: 62 },
  { iconKey: 'oxygen', colorKey: 'oxygen', label: 'Oxygen', sample: 54 },
]

const vehicleEditors: { iconKey: keyof Theme['icons']; label: string; sample: number }[] = [
  { iconKey: 'fuel', label: 'Fuel', sample: 68 },
  { iconKey: 'seatbelt', label: 'Seatbelt', sample: 100 },
]

const speedStyles: { id: SpeedStyle; label: string; hint: string }[] = [
  { id: 'digitalArc', label: 'Digital + bar', hint: 'Speed digits with an RPM bar' },
  { id: 'digital', label: 'Digital', hint: 'Speed digits and vehicle stats' },
  { id: 'minimal', label: 'Minimal', hint: 'Speed only — no fuel or gear' },
  { id: 'analog', label: 'Analog', hint: 'Needle gauge with tick marks' },
  { id: 'circular', label: 'Circular', hint: 'Ring gauge with speed in the center' },
]

function sameHex(a: string, b: string) {
  return a.replace('#', '').toLowerCase() === b.replace('#', '').toLowerCase()
}

function update<K extends keyof Theme>(key: K, value: Theme[K]) {
  draft.value = mergeTheme(defaultTheme, { ...draft.value, [key]: value })
  emit('preview', draft.value)
}

function nested<G extends 'status' | 'compass' | 'identity' | 'icons' | 'visibility' | 'vehicle' | 'colors' | 'thresholds'>(
  group: G,
  key: string,
  value: unknown,
) {
  draft.value = mergeTheme(defaultTheme, {
    ...draft.value,
    [group]: {
      ...draft.value[group],
      [key]: value,
    },
  })
  emit('preview', draft.value)
}

function setSurfaceColor(key: 'surface' | 'surfaceStrong' | 'muted', hex: string) {
  const parsed = parseColor(draft.value[key])
  update(key, toRgba(hex, parsed.alpha))
}

function setSurfaceAlpha(key: 'surface' | 'surfaceStrong' | 'muted', alpha: number) {
  const parsed = parseColor(draft.value[key])
  update(key, toRgba(parsed.hex, alpha))
}

function surfaceAlpha(key: 'surface' | 'surfaceStrong' | 'muted') {
  return parseColor(draft.value[key]).alpha
}

function surfaceHex(key: 'surface' | 'surfaceStrong' | 'muted') {
  return parseColor(draft.value[key]).hex
}

function setStatColor(key: keyof Theme['colors'], value: string) {
  nested('colors', key, value)
}

function save() {
  const theme = mergeTheme(defaultTheme, draft.value)
  draft.value = theme
  emit('preview', theme)
  nuiPost('saveTheme', { theme })
  saved.value = true
  window.setTimeout(() => {
    saved.value = false
  }, 1600)
}

function reset() {
  nuiPost('resetTheme')
}

function close() {
  nuiPost('closeAdmin')
}

defineExpose({
  sync(theme: Theme) {
    draft.value = mergeTheme(defaultTheme, theme)
  },
})
</script>

<template>
  <section class="ap">
    <header class="ap-head">
      <div>
        <h1>Look editor</h1>
        <p>Server-wide · live preview on the HUD</p>
      </div>
      <button class="ap-x" type="button" @click="close">Close</button>
    </header>

    <div class="ap-shell">
      <nav class="ap-nav">
        <button type="button" :class="{ on: tab === 'layout' }" @click="tab = 'layout'">Place</button>
        <button type="button" :class="{ on: tab === 'badges' }" @click="tab = 'badges'">Badges</button>
        <button type="button" :class="{ on: tab === 'icons' }" @click="tab = 'icons'">Icons</button>
        <button type="button" :class="{ on: tab === 'visibility' }" @click="tab = 'visibility'">Show</button>
        <button type="button" :class="{ on: tab === 'vehicle' }" @click="tab = 'vehicle'">Vehicle</button>
      </nav>

      <div class="ap-main">
        <template v-if="tab === 'layout'">
          <section class="ap-section">
            <header class="ap-section-head">
              <h2>Status cluster</h2>
              <p class="ap-hint">Core vitals dock — position, spacing, and badge scale.</p>
            </header>
            <div class="ap-section-body">
              <div class="ap-screen">
                <button
                  v-for="item in positions"
                  :key="item.id"
                  type="button"
                  class="ap-pin"
                  :class="[item.slot, { on: draft.status.position === item.id }]"
                  :title="item.label"
                  @click="nested('status', 'position', item.id)"
                />
              </div>
              <p class="ap-placement-label">{{ positions.find((item) => item.id === draft.status.position)?.label }}</p>
              <div class="ap-slider-grid">
                <label class="ap-slider">
                  <span>Offset X <b>{{ draft.status.offsetX.toFixed(1) }}</b></span>
                  <input type="range" min="0" max="8" step="0.1" :value="draft.status.offsetX" @input="nested('status', 'offsetX', Number(($event.target as HTMLInputElement).value))" />
                </label>
                <label class="ap-slider">
                  <span>Offset Y <b>{{ draft.status.offsetY.toFixed(1) }}</b></span>
                  <input type="range" min="0" max="8" step="0.1" :value="draft.status.offsetY" @input="nested('status', 'offsetY', Number(($event.target as HTMLInputElement).value))" />
                </label>
                <label class="ap-slider">
                  <span>Badge size <b>{{ draft.statusSize.toFixed(2) }}</b></span>
                  <input type="range" min="0.75" max="1.35" step="0.05" :value="draft.statusSize" @input="update('statusSize', Number(($event.target as HTMLInputElement).value))" />
                </label>
              </div>
            </div>
          </section>

          <div class="ap-section-row">
            <section class="ap-section">
              <header class="ap-section-head">
                <h2>Compass</h2>
                <p class="ap-hint">Heading and street readout.</p>
              </header>
              <div class="ap-section-body">
                <div class="ap-screen ap-screen-sm">
                  <button
                    v-for="item in hudAnchors"
                    :key="`compass-${item.id}`"
                    type="button"
                    class="ap-pin"
                    :class="[item.slot, { on: draft.compass.position === item.id }]"
                    :title="item.label"
                    @click="nested('compass', 'position', item.id)"
                  />
                </div>
                <p class="ap-placement-label">{{ hudAnchors.find((item) => item.id === draft.compass.position)?.label }}</p>
                <label class="ap-slider">
                  <span>Offset X <b>{{ draft.compass.offsetX.toFixed(1) }}</b></span>
                  <input type="range" min="0" max="8" step="0.1" :value="draft.compass.offsetX" @input="nested('compass', 'offsetX', Number(($event.target as HTMLInputElement).value))" />
                </label>
                <label class="ap-slider">
                  <span>Offset Y <b>{{ draft.compass.offsetY.toFixed(1) }}</b></span>
                  <input type="range" min="0" max="8" step="0.1" :value="draft.compass.offsetY" @input="nested('compass', 'offsetY', Number(($event.target as HTMLInputElement).value))" />
                </label>
                <label class="ap-toggle">
                  <div>
                    <span>Dark fill</span>
                    <small>Readable on bright scenes</small>
                  </div>
                  <input
                    type="checkbox"
                    :checked="draft.compassBackground !== false"
                    @change="update('compassBackground', ($event.target as HTMLInputElement).checked)"
                  />
                  <i />
                </label>
              </div>
            </section>

            <section class="ap-section">
              <header class="ap-section-head">
                <h2>Identity</h2>
                <p class="ap-hint">Job and money chips.</p>
              </header>
              <div class="ap-section-body">
                <div class="ap-screen ap-screen-sm">
                  <button
                    v-for="item in hudAnchors"
                    :key="`identity-${item.id}`"
                    type="button"
                    class="ap-pin"
                    :class="[item.slot, { on: draft.identity.position === item.id }]"
                    :title="item.label"
                    @click="nested('identity', 'position', item.id)"
                  />
                </div>
                <p class="ap-placement-label">{{ hudAnchors.find((item) => item.id === draft.identity.position)?.label }}</p>
                <label class="ap-slider">
                  <span>Offset X <b>{{ draft.identity.offsetX.toFixed(1) }}</b></span>
                  <input type="range" min="0" max="8" step="0.1" :value="draft.identity.offsetX" @input="nested('identity', 'offsetX', Number(($event.target as HTMLInputElement).value))" />
                </label>
                <label class="ap-slider">
                  <span>Offset Y <b>{{ draft.identity.offsetY.toFixed(1) }}</b></span>
                  <input type="range" min="0" max="8" step="0.1" :value="draft.identity.offsetY" @input="nested('identity', 'offsetY', Number(($event.target as HTMLInputElement).value))" />
                </label>
              </div>
            </section>
          </div>

          <section class="ap-section">
            <header class="ap-section-head">
              <h2>Palette</h2>
              <p class="ap-hint">Primary HUD colors.</p>
            </header>
            <div class="ap-section-body">
              <div class="ap-colors ap-colors-wide">
                <label class="ap-color">
                  <span class="ap-swatch" :style="{ '--swatch': draft.text }">
                    <input type="color" :value="draft.text" @input="update('text', ($event.target as HTMLInputElement).value)" />
                  </span>
                  <span>Text</span>
                  <b>{{ draft.text.toUpperCase() }}</b>
                </label>
                <label class="ap-color">
                  <span class="ap-swatch" :style="{ '--swatch': draft.accent }">
                    <input type="color" :value="draft.accent" @input="update('accent', ($event.target as HTMLInputElement).value)" />
                  </span>
                  <span>Accent</span>
                  <b>{{ draft.accent.toUpperCase() }}</b>
                </label>
                <label class="ap-color">
                  <span class="ap-swatch" :style="{ '--swatch': draft.warning }">
                    <input type="color" :value="draft.warning" @input="update('warning', ($event.target as HTMLInputElement).value)" />
                  </span>
                  <span>Warning</span>
                  <b>{{ draft.warning.toUpperCase() }}</b>
                </label>
                <label class="ap-color">
                  <span class="ap-swatch" :style="{ '--swatch': draft.critical }">
                    <input type="color" :value="draft.critical" @input="update('critical', ($event.target as HTMLInputElement).value)" />
                  </span>
                  <span>Critical</span>
                  <b>{{ draft.critical.toUpperCase() }}</b>
                </label>
              </div>
            </div>
          </section>

          <section class="ap-section">
            <header class="ap-section-head">
              <h2>Glass & surfaces</h2>
              <p class="ap-hint">Panel fills, blur, and corner radius.</p>
            </header>
            <div class="ap-section-body">
              <div class="ap-surface-grid">
                <article v-for="key in ['surface', 'surfaceStrong', 'muted'] as const" :key="key" class="ap-surface-card">
                  <label class="ap-color ap-surface-head">
                    <span class="ap-swatch" :style="{ '--swatch': draft[key] }">
                      <input
                        type="color"
                        :value="surfaceHex(key)"
                        @input="setSurfaceColor(key, ($event.target as HTMLInputElement).value)"
                      />
                    </span>
                    <span>{{ key === 'surfaceStrong' ? 'Surface strong' : key === 'surface' ? 'Surface' : 'Muted' }}</span>
                    <b>{{ draft[key] }}</b>
                  </label>
                  <label class="ap-slider ap-surface-alpha">
                    <span>Opacity <b>{{ surfaceAlpha(key).toFixed(2) }}</b></span>
                    <input
                      type="range"
                      min="0"
                      max="1"
                      step="0.02"
                      :value="surfaceAlpha(key)"
                      @input="setSurfaceAlpha(key, Number(($event.target as HTMLInputElement).value))"
                    />
                  </label>
                </article>
              </div>
              <div class="ap-slider-grid ap-slider-grid-2">
                <label class="ap-slider">
                  <span>Blur <b>{{ draft.blur }}</b></span>
                  <input type="range" min="0" max="28" :value="draft.blur" @input="update('blur', Number(($event.target as HTMLInputElement).value))" />
                </label>
                <label class="ap-slider">
                  <span>Corners <b>{{ draft.radius }}</b></span>
                  <input type="range" min="0" max="28" :value="draft.radius" @input="update('radius', Number(($event.target as HTMLInputElement).value))" />
                </label>
              </div>
            </div>
          </section>
        </template>

        <template v-if="tab === 'badges'">
          <section class="ap-section">
            <header class="ap-section-head">
              <h2>Layout</h2>
              <p class="ap-hint">How each status badge displays its value.</p>
            </header>
            <div class="ap-section-body">
              <div class="ap-layouts">
                <button
                  v-for="item in layouts"
                  :key="item.id"
                  type="button"
                  :class="{ on: draft.badgeLayout === item.id }"
                  @click="update('badgeLayout', item.id)"
                >
                  <div class="ap-demo">
                    <StatusPill
                      :value="68"
                      :icon="draft.icons.health"
                      :color="draft.colors.health"
                      :layout="item.id"
                      :shape="draft.badgeShape"
                      :badge-style="draft.badgeStyle"
                      :ring-background="item.id === 'ring' ? draft.ringBackground : false"
                    />
                  </div>
                  <span>{{ item.label }}</span>
                </button>
              </div>
              <label v-if="draft.badgeLayout === 'ring'" class="ap-toggle">
                <div>
                  <span>Dark fill</span>
                  <small>Dark background inside the ring — progress stays on the ring</small>
                </div>
                <input
                  type="checkbox"
                  :checked="draft.ringBackground"
                  @change="update('ringBackground', ($event.target as HTMLInputElement).checked)"
                />
                <i />
              </label>
            </div>
          </section>

          <section class="ap-section">
            <header class="ap-section-head">
              <h2>Style</h2>
              <p class="ap-hint">Shape and icon weight for all badges.</p>
            </header>
            <div class="ap-section-body">
              <div class="ap-field">
                <span class="ap-field-label">Shape</span>
                <div class="ap-seg">
                  <button type="button" :class="{ on: draft.badgeShape === 'circle' }" @click="update('badgeShape', 'circle')">Circle</button>
                  <button type="button" :class="{ on: draft.badgeShape === 'rounded' }" @click="update('badgeShape', 'rounded')">Rounded</button>
                </div>
              </div>
              <div class="ap-field">
                <span class="ap-field-label">Icon weight</span>
                <div class="ap-seg">
                  <button type="button" :class="{ on: draft.badgeStyle === 'filled' }" @click="update('badgeStyle', 'filled')">Filled</button>
                  <button type="button" :class="{ on: draft.badgeStyle === 'outline' }" @click="update('badgeStyle', 'outline')">Outline</button>
                  <button type="button" :class="{ on: draft.badgeStyle === 'duotone' }" @click="update('badgeStyle', 'duotone')">Duotone</button>
                </div>
              </div>
            </div>
          </section>
        </template>

        <template v-if="tab === 'icons'">
          <section class="ap-section ap-section-flush">
            <header class="ap-section-head">
              <h2>Status glyphs</h2>
              <p class="ap-hint">Pick a glyph and color for each vital.</p>
            </header>
          </section>
          <article v-for="item in coreEditors" :key="item.iconKey" class="ap-stat">
            <header class="ap-stat-head">
              <StatusPill
                :value="item.sample"
                :icon="draft.icons[item.iconKey]"
                :color="draft.colors[item.colorKey]"
                :layout="draft.badgeLayout"
                :shape="draft.badgeShape"
                :badge-style="draft.badgeStyle"
                :ring-background="draft.ringBackground"
              />
              <div class="ap-stat-meta">
                <strong>{{ item.label }}</strong>
                <span>{{ draft.colors[item.colorKey].toUpperCase() }}</span>
              </div>
              <div class="ap-stat-paint">
                <button
                  v-for="hex in STAT_PALETTES[item.colorKey]"
                  :key="hex"
                  type="button"
                  class="ap-chip"
                  :class="{ on: sameHex(draft.colors[item.colorKey], hex) }"
                  :style="{ background: hex }"
                  :title="hex"
                  @click="setStatColor(item.colorKey, hex)"
                />
                <label class="ap-swatch" :style="{ '--swatch': draft.colors[item.colorKey] }" title="Custom color">
                  <input
                    type="color"
                    :value="draft.colors[item.colorKey]"
                    @input="setStatColor(item.colorKey, ($event.target as HTMLInputElement).value)"
                  />
                </label>
              </div>
            </header>
            <div class="ap-icon-grid" :style="{ '--stat': draft.colors[item.colorKey] }">
              <button
                v-for="icon in ICON_OPTIONS"
                :key="icon"
                type="button"
                :class="{ on: draft.icons[item.iconKey] === icon }"
                :title="icon"
                @click="nested('icons', item.iconKey, icon)"
              >
                <HudIcon :name="icon" :badge-style="draft.badgeStyle" />
              </button>
            </div>
          </article>

          <section class="ap-section ap-section-flush">
            <header class="ap-section-head">
              <h2>Vehicle glyphs</h2>
              <p class="ap-hint">Fuel and seatbelt icons — use accent color.</p>
            </header>
          </section>
          <article v-for="item in vehicleEditors" :key="item.iconKey" class="ap-stat">
            <header class="ap-stat-head">
              <StatusPill
                :value="item.sample"
                :icon="draft.icons[item.iconKey]"
                :color="draft.accent"
                :layout="draft.badgeLayout"
                :shape="draft.badgeShape"
                :badge-style="draft.badgeStyle"
                :ring-background="draft.ringBackground"
              />
              <div class="ap-stat-meta">
                <strong>{{ item.label }}</strong>
                <span>Uses accent</span>
              </div>
            </header>
            <div class="ap-icon-grid" :style="{ '--stat': draft.accent }">
              <button
                v-for="icon in ICON_OPTIONS"
                :key="icon"
                type="button"
                :class="{ on: draft.icons[item.iconKey] === icon }"
                :title="icon"
                @click="nested('icons', item.iconKey, icon)"
              >
                <HudIcon :name="icon" :badge-style="draft.badgeStyle" />
              </button>
            </div>
          </article>
        </template>

        <template v-if="tab === 'visibility'">
          <section class="ap-section">
            <header class="ap-section-head">
              <h2>Persistent</h2>
              <p class="ap-hint">Elements that stay visible when enabled.</p>
            </header>
            <div class="ap-section-body ap-toggle-stack">
              <label class="ap-toggle">
                <div>
                  <span>Compass</span>
                  <small>Heading and street name</small>
                </div>
                <input type="checkbox" :checked="draft.visibility.compass" @change="nested('visibility', 'compass', ($event.target as HTMLInputElement).checked)" />
                <i />
              </label>
              <label class="ap-toggle">
                <div>
                  <span>GPS waypoint</span>
                  <small>Distance and direction when a route is set</small>
                </div>
                <input type="checkbox" :checked="draft.visibility.waypoint !== false" @change="nested('visibility', 'waypoint', ($event.target as HTMLInputElement).checked)" />
                <i />
              </label>
              <label class="ap-toggle">
                <div>
                  <span>Money</span>
                  <small>Always show cash and bank</small>
                </div>
                <input type="checkbox" :checked="draft.visibility.money" @change="nested('visibility', 'money', ($event.target as HTMLInputElement).checked)" />
                <i />
              </label>
              <label class="ap-toggle">
                <div>
                  <span>Job</span>
                  <small>Always show job label</small>
                </div>
                <input type="checkbox" :checked="draft.visibility.job" @change="nested('visibility', 'job', ($event.target as HTMLInputElement).checked)" />
                <i />
              </label>
              <label class="ap-toggle">
                <div>
                  <span>Stress</span>
                  <small>When the framework provides it</small>
                </div>
                <input type="checkbox" :checked="draft.visibility.stress" @change="nested('visibility', 'stress', ($event.target as HTMLInputElement).checked)" />
                <i />
              </label>
            </div>
          </section>

          <section class="ap-section">
            <header class="ap-section-head">
              <h2>Behavior</h2>
              <p class="ap-hint">Peek and minimap rules.</p>
            </header>
            <div class="ap-section-body ap-toggle-stack">
              <label class="ap-toggle">
                <div>
                  <span>Peek money</span>
                  <small>Hold Alt or use /cash</small>
                </div>
                <input type="checkbox" :checked="draft.visibility.peekMoney" @change="nested('visibility', 'peekMoney', ($event.target as HTMLInputElement).checked)" />
                <i />
              </label>
              <label class="ap-toggle">
                <div>
                  <span>Radar on foot</span>
                  <small>Keep the minimap visible when walking</small>
                </div>
                <input type="checkbox" :checked="draft.visibility.radarOnFoot" @change="nested('visibility', 'radarOnFoot', ($event.target as HTMLInputElement).checked)" />
                <i />
              </label>
            </div>
          </section>

          <section class="ap-section">
            <header class="ap-section-head">
              <h2>Quiet cluster</h2>
              <p class="ap-hint">Hide badges when values are unimportant.</p>
            </header>
            <div class="ap-section-body ap-toggle-stack">
              <label class="ap-toggle">
                <div>
                  <span>Hide armor at zero</span>
                  <small>Remove the armor badge when empty</small>
                </div>
                <input
                  type="checkbox"
                  :checked="draft.thresholds.hideArmorAtZero !== false"
                  @change="nested('thresholds', 'hideArmorAtZero', ($event.target as HTMLInputElement).checked)"
                />
                <i />
              </label>
              <label class="ap-toggle">
                <div>
                  <span>Hide full needs</span>
                  <small>Hide hunger and thirst when nearly full</small>
                </div>
                <input
                  type="checkbox"
                  :checked="draft.thresholds.hideNeedsWhenFull !== false"
                  @change="nested('thresholds', 'hideNeedsWhenFull', ($event.target as HTMLInputElement).checked)"
                />
                <i />
              </label>
              <label v-if="draft.thresholds.hideNeedsWhenFull !== false" class="ap-slider">
                <span>Full above <b>{{ draft.thresholds.needsFullAt ?? 95 }}%</b></span>
                <input
                  type="range"
                  min="80"
                  max="100"
                  step="1"
                  :value="draft.thresholds.needsFullAt ?? 95"
                  @input="nested('thresholds', 'needsFullAt', Number(($event.target as HTMLInputElement).value))"
                />
              </label>
            </div>
          </section>

          <section class="ap-section">
            <header class="ap-section-head">
              <h2>Contextual</h2>
              <p class="ap-hint">Appear only when relevant in-game.</p>
            </header>
            <div class="ap-section-body ap-toggle-stack">
              <label v-for="item in contextualToggles" :key="item.key" class="ap-toggle">
                <div>
                  <span>{{ item.label }}</span>
                  <small>{{ item.hint }}</small>
                </div>
                <input
                  type="checkbox"
                  :checked="draft.visibility[item.key] !== false"
                  @change="nested('visibility', item.key, ($event.target as HTMLInputElement).checked)"
                />
                <i />
              </label>
            </div>
          </section>
        </template>

        <template v-if="tab === 'vehicle'">
          <section class="ap-section">
            <header class="ap-section-head">
              <h2>Speed readout</h2>
              <p class="ap-hint">Units and speed display style.</p>
            </header>
            <div class="ap-section-body">
              <div class="ap-field">
                <span class="ap-field-label">Units</span>
                <div class="ap-seg">
                  <button type="button" :class="{ on: draft.vehicle.units === 'mph' }" @click="nested('vehicle', 'units', 'mph')">MPH</button>
                  <button type="button" :class="{ on: draft.vehicle.units === 'kph' }" @click="nested('vehicle', 'units', 'kph')">KPH</button>
                </div>
              </div>
              <div class="ap-field">
                <span class="ap-field-label">Style</span>
                <div class="ap-style-grid">
                  <button
                    v-for="item in speedStyles"
                    :key="item.id"
                    type="button"
                    :class="{ on: draft.vehicle.speedStyle === item.id }"
                    @click="nested('vehicle', 'speedStyle', item.id)"
                  >
                    <strong>{{ item.label }}</strong>
                    <small>{{ item.hint }}</small>
                  </button>
                </div>
              </div>
              <div class="ap-field">
                <span class="ap-field-label">Minimap</span>
                <div class="ap-seg">
                  <button type="button" :class="{ on: draft.vehicle.minimapShape !== 'circle' }" @click="nested('vehicle', 'minimapShape', 'square')">Square</button>
                  <button type="button" :class="{ on: draft.vehicle.minimapShape === 'circle' }" @click="nested('vehicle', 'minimapShape', 'circle')">Circle</button>
                </div>
              </div>
              <label class="ap-toggle">
                <div>
                  <span>Dark fill</span>
                  <small>Compact panel behind speed and stats only</small>
                </div>
                <input
                  type="checkbox"
                  :checked="draft.vehicle.readoutBackground !== false"
                  @change="nested('vehicle', 'readoutBackground', ($event.target as HTMLInputElement).checked)"
                />
                <i />
              </label>
            </div>
          </section>

          <section class="ap-section">
            <header class="ap-section-head">
              <h2>Details</h2>
              <p class="ap-hint">Extra info shown in the vehicle scene. Hidden on the minimal speedometer.</p>
            </header>
            <div class="ap-section-body ap-toggle-stack">
              <label class="ap-toggle">
                <div>
                  <span>Gear</span>
                  <small>Current gear next to fuel</small>
                </div>
                <input type="checkbox" :checked="draft.vehicle.showGear" @change="nested('vehicle', 'showGear', ($event.target as HTMLInputElement).checked)" />
                <i />
              </label>
              <label class="ap-toggle">
                <div>
                  <span>Fuel</span>
                  <small>Pump icon and level bar</small>
                </div>
                <input type="checkbox" :checked="draft.vehicle.showFuel" @change="nested('vehicle', 'showFuel', ($event.target as HTMLInputElement).checked)" />
                <i />
              </label>
              <label class="ap-toggle">
                <div>
                  <span>Engine</span>
                  <small>Engine health bar</small>
                </div>
                <input type="checkbox" :checked="draft.vehicle.showEngine" @change="nested('vehicle', 'showEngine', ($event.target as HTMLInputElement).checked)" />
                <i />
              </label>
              <label class="ap-toggle">
                <div>
                  <span>Cruise control</span>
                  <small>When cruise state is active</small>
                </div>
                <input
                  type="checkbox"
                  :checked="draft.vehicle.showCruise !== false"
                  @change="nested('vehicle', 'showCruise', ($event.target as HTMLInputElement).checked)"
                />
                <i />
              </label>
            </div>
          </section>
        </template>
      </div>
    </div>

    <footer class="ap-foot">
      <button type="button" @click="reset">Reset</button>
      <button type="button" class="primary" @click="save">{{ saved ? 'Saved' : 'Save for everyone' }}</button>
    </footer>
  </section>
</template>
