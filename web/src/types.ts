export type BadgeStyle = 'filled' | 'outline' | 'duotone'
export type BadgeLayout = 'ring' | 'percent' | 'fill' | 'bars'
export type BadgeShape = 'circle' | 'rounded'
export type StatusPosition = 'bottom-left' | 'bottom-center' | 'bottom-right' | 'top-left' | 'top-right'
export type HudAnchor = StatusPosition | 'top-center'
export type SpeedStyle = 'digitalArc' | 'digital' | 'minimal' | 'analog' | 'circular'
export type MinimapShape = 'square' | 'circle'

export interface HudPlacement {
  position: HudAnchor
  offsetX: number
  offsetY: number
}

export interface ThemeIcons {
  health: string
  armor: string
  hunger: string
  thirst: string
  stress: string
  fuel: string
  seatbelt: string
  voice: string
  stamina: string
  oxygen: string
}

export interface ThemeColors {
  health: string
  armor: string
  hunger: string
  thirst: string
  stress: string
  stamina: string
  oxygen: string
  voice: string
}

export interface Theme {
  schema: number
  preset: string
  accent: string
  surface: string
  surfaceStrong: string
  text: string
  muted: string
  warning: string
  critical: string
  blur: number
  radius: number
  statusSize: number
  badgeStyle: BadgeStyle
  badgeLayout: BadgeLayout
  badgeShape: BadgeShape
  ringBackground: boolean
  status: HudPlacement & { position: StatusPosition }
  compass: HudPlacement
  identity: HudPlacement
  compassBackground: boolean
  icons: ThemeIcons
  colors: ThemeColors
  visibility: {
    compass: boolean
    money: boolean
    job: boolean
    radarOnFoot: boolean
    peekMoney: boolean
    stress: boolean
    voice: boolean
    voiceModeLabel: boolean
    waypoint: boolean
    stamina: boolean
    oxygen: boolean
    ammo: boolean
    parachute: boolean
    harness: boolean
  }
  thresholds: {
    hideArmorAtZero: boolean
    hideNeedsWhenFull: boolean
    needsFullAt: number
  }
  vehicle: {
    units: 'mph' | 'kph'
    speedStyle: SpeedStyle
    showGear: boolean
    showFuel: boolean
    showEngine: boolean
    showCruise: boolean
    readoutBackground: boolean
    minimapShape: MinimapShape
  }
}

export type FuelKind = 'petrol' | 'electric'

export interface ExtraStatus {
  id: string
  value: number
  icon: string
  color: string
}

export interface VehicleState {
  active: boolean
  speed: number
  rpm: number
  gear: string
  fuel: number
  engine: number
  fuelKind: FuelKind
  seatbelt: boolean
  seatbeltVisible: boolean
  cruise: boolean
  airborne: boolean
  altitude: number
  heading: number
}

export interface HudState {
  health: number
  armor: number
  hunger: number
  thirst: number
  stress: number | null
  voice: { talking: boolean; mode: number; radio: boolean }
  stamina: number
  staminaActive: boolean
  oxygen: number
  oxygenActive: boolean
  weapon: {
    show: boolean
    hash?: number
    clip?: number
    reserve?: number
    hasAmmo?: boolean
    label?: string
    fireMode?: string
  } | null
  extras: ExtraStatus[]
  parachute: boolean
  harness: boolean
  vehicle: VehicleState
  compass: {
    heading: number
    cardinal: string
    street: string
    crossing: string
    zone: string
    waypoint: {
      active: boolean
      distance: number
      direction: string
    } | null
  }
  identity: {
    job: string
    cash: number
    bank: number
    peek: boolean
    showMoney: boolean
    showJob: boolean
  }
}

export const defaultTheme: Theme = {
  schema: 1,
  preset: 'nightGlass',
  accent: '#007BC7',
  surface: 'rgba(8, 8, 8, 0.42)',
  surfaceStrong: 'rgba(10, 10, 10, 0.92)',
  text: '#FFFFFF',
  muted: 'rgba(236, 232, 225, 0.42)',
  warning: '#C7924A',
  critical: '#D45B4A',
  blur: 10,
  radius: 4,
  statusSize: 1,
  badgeStyle: 'filled',
  badgeLayout: 'ring',
  badgeShape: 'circle',
  ringBackground: true,
  status: {
    position: 'bottom-center',
    offsetX: 1.8,
    offsetY: 2.6,
  },
  compass: {
    position: 'top-center',
    offsetX: 0,
    offsetY: 2,
  },
  identity: {
    position: 'top-right',
    offsetX: 2.2,
    offsetY: 2,
  },
  compassBackground: true,
  icons: {
    health: 'heart',
    armor: 'shield',
    hunger: 'utensils',
    thirst: 'droplet',
    stress: 'activity',
    fuel: 'fuel',
    seatbelt: 'seatbelt',
    voice: 'mic',
    stamina: 'wind',
    oxygen: 'waves',
  },
  colors: {
    health: '#D45B4A',
    armor: '#4CB8A8',
    hunger: '#D47A32',
    thirst: '#4A82C4',
    stress: '#8B6BC8',
    stamina: '#D4B46A',
    oxygen: '#5AA4B4',
    voice: '#E4DDD2',
  },
  visibility: {
    compass: true,
    money: false,
    job: false,
    radarOnFoot: false,
    peekMoney: true,
    stress: false,
    voice: true,
    voiceModeLabel: true,
    waypoint: true,
    stamina: true,
    oxygen: true,
    ammo: true,
    parachute: true,
    harness: true,
  },
  thresholds: {
    hideArmorAtZero: true,
    hideNeedsWhenFull: true,
    needsFullAt: 95,
  },
  vehicle: {
    units: 'mph',
    speedStyle: 'digitalArc',
    showGear: true,
    showFuel: true,
    showEngine: true,
    showCruise: true,
    readoutBackground: true,
    minimapShape: 'square',
  },
}

export const defaultState: HudState = {
  health: 100,
  armor: 0,
  hunger: 100,
  thirst: 100,
  stress: null,
  voice: { talking: false, mode: 2, radio: false },
  stamina: 100,
  staminaActive: false,
  oxygen: 100,
  oxygenActive: false,
  weapon: null,
  extras: [],
  parachute: false,
  harness: false,
  vehicle: {
    active: false,
    speed: 0,
    rpm: 0,
    gear: 'N',
    fuel: 0,
    engine: 100,
    fuelKind: 'petrol',
    seatbelt: false,
    seatbeltVisible: false,
    cruise: false,
    airborne: false,
    altitude: 0,
    heading: 0,
  },
  compass: {
    heading: 0,
    cardinal: 'N',
    street: '',
    crossing: '',
    zone: '',
    waypoint: null,
  },
  identity: {
    job: '',
    cash: 0,
    bank: 0,
    peek: false,
    showMoney: false,
    showJob: false,
  },
}

export const ICON_NAMES = [
  'heart',
  'shield',
  'utensils',
  'droplet',
  'activity',
  'fuel',
  'seatbelt',
  'mic',
  'wind',
  'waves',
  'bolt',
  'crosshair',
  'star',
  'parachute',
] as const

const BADGE_STYLES: BadgeStyle[] = ['filled', 'outline', 'duotone']
const BADGE_LAYOUTS: BadgeLayout[] = ['ring', 'percent', 'fill', 'bars']
const BADGE_SHAPES: BadgeShape[] = ['circle', 'rounded']
const STATUS_POSITIONS: StatusPosition[] = [
  'bottom-left',
  'bottom-center',
  'bottom-right',
  'top-left',
  'top-right',
]
const HUD_ANCHORS: HudAnchor[] = [
  'bottom-left',
  'bottom-center',
  'bottom-right',
  'top-left',
  'top-center',
  'top-right',
]
const SPEED_STYLES: SpeedStyle[] = ['digitalArc', 'digital', 'minimal', 'analog', 'circular']
const MINIMAP_SHAPES: MinimapShape[] = ['square', 'circle']
const COLOR_RE =
  /^(#(?:[0-9a-fA-F]{3}|[0-9a-fA-F]{6})|rgba?\(\s*\d+\s*,\s*\d+\s*,\s*\d+(?:\s*,\s*[\d.]+)?\s*\))$/

function clamp(value: number, min: number, max: number, fallback: number) {
  if (!Number.isFinite(value)) return fallback
  return Math.min(max, Math.max(min, value))
}

function pick<T extends string>(value: unknown, allowed: readonly T[], fallback: T): T {
  return allowed.includes(value as T) ? (value as T) : fallback
}

function asBool(value: unknown, fallback: boolean) {
  return typeof value === 'boolean' ? value : fallback
}

function asColor(value: unknown, fallback: string) {
  return typeof value === 'string' && COLOR_RE.test(value) ? value : fallback
}

function asIcon(value: unknown, fallback: string) {
  return typeof value === 'string' && (ICON_NAMES as readonly string[]).includes(value)
    ? value
    : fallback
}

function asPlacement(
  value: Partial<HudPlacement> | undefined,
  fallback: HudPlacement,
  allowed: readonly string[],
): HudPlacement {
  return {
    position: pick(value?.position, allowed, fallback.position) as HudAnchor,
    offsetX: clamp(Number(value?.offsetX), 0, 8, fallback.offsetX),
    offsetY: clamp(Number(value?.offsetY), 0, 8, fallback.offsetY),
  }
}

export function mergeTheme(base: Theme, override: Partial<Theme> | null | undefined): Theme {
  const src = { ...base, ...(override || {}) }
  const status = { ...base.status, ...(override?.status || {}) }
  const compass = { ...base.compass, ...(override?.compass || {}) }
  const identity = { ...base.identity, ...(override?.identity || {}) }
  const icons = { ...base.icons, ...(override?.icons || {}) }
  const colors = { ...base.colors, ...(override?.colors || {}) }
  const visibility = { ...base.visibility, ...(override?.visibility || {}) }
  const thresholds = { ...base.thresholds, ...(override?.thresholds || {}) }
  const vehicle = { ...base.vehicle, ...(override?.vehicle || {}) }

  const next: Theme = {
    schema: 1,
    preset: typeof src.preset === 'string' ? src.preset.slice(0, 32) : base.preset,
    accent: asColor(src.accent, base.accent),
    surface: asColor(src.surface, base.surface),
    surfaceStrong: asColor(src.surfaceStrong, base.surfaceStrong),
    text: asColor(src.text, base.text),
    muted: asColor(src.muted, base.muted),
    warning: asColor(src.warning, base.warning),
    critical: asColor(src.critical, base.critical),
    blur: clamp(Number(src.blur), 0, 28, base.blur),
    radius: clamp(Number(src.radius), 0, 28, base.radius),
    statusSize: clamp(Number(src.statusSize), 0.75, 1.35, base.statusSize),
    badgeStyle: pick(src.badgeStyle, BADGE_STYLES, base.badgeStyle),
    badgeLayout: pick(src.badgeLayout, BADGE_LAYOUTS, base.badgeLayout),
    badgeShape: pick(src.badgeShape, BADGE_SHAPES, base.badgeShape),
    ringBackground: asBool(src.ringBackground, base.ringBackground),
    status: asPlacement(status, base.status, STATUS_POSITIONS) as Theme['status'],
    compass: asPlacement(compass, base.compass, HUD_ANCHORS),
    identity: asPlacement(identity, base.identity, HUD_ANCHORS),
    compassBackground: asBool(src.compassBackground, base.compassBackground),
    icons: {
      health: asIcon(icons.health, base.icons.health),
      armor: asIcon(icons.armor, base.icons.armor),
      hunger: asIcon(icons.hunger, base.icons.hunger),
      thirst: asIcon(icons.thirst, base.icons.thirst),
      stress: asIcon(icons.stress, base.icons.stress),
      fuel: asIcon(icons.fuel, base.icons.fuel),
      seatbelt: asIcon(icons.seatbelt, base.icons.seatbelt),
      voice: asIcon(icons.voice, base.icons.voice),
      stamina: asIcon(icons.stamina, base.icons.stamina),
      oxygen: asIcon(icons.oxygen, base.icons.oxygen),
    },
    colors: {
      health: asColor(colors.health, base.colors.health),
      armor: asColor(colors.armor, base.colors.armor),
      hunger: asColor(colors.hunger, base.colors.hunger),
      thirst: asColor(colors.thirst, base.colors.thirst),
      stress: asColor(colors.stress, base.colors.stress),
      stamina: asColor(colors.stamina, base.colors.stamina),
      oxygen: asColor(colors.oxygen, base.colors.oxygen),
      voice: asColor(colors.voice, base.colors.voice),
    },
    visibility: {
      compass: asBool(visibility.compass, base.visibility.compass),
      money: asBool(visibility.money, base.visibility.money),
      job: asBool(visibility.job, base.visibility.job),
      radarOnFoot: asBool(visibility.radarOnFoot, base.visibility.radarOnFoot),
      peekMoney: asBool(visibility.peekMoney, base.visibility.peekMoney),
      stress: asBool(visibility.stress, base.visibility.stress),
      voice: asBool(visibility.voice, base.visibility.voice),
      voiceModeLabel: asBool(visibility.voiceModeLabel, base.visibility.voiceModeLabel),
      waypoint: asBool(visibility.waypoint, base.visibility.waypoint),
      stamina: asBool(visibility.stamina, base.visibility.stamina),
      oxygen: asBool(visibility.oxygen, base.visibility.oxygen),
      ammo: asBool(visibility.ammo, base.visibility.ammo),
      parachute: asBool(visibility.parachute, base.visibility.parachute),
      harness: asBool(visibility.harness, base.visibility.harness),
    },
    thresholds: {
      hideArmorAtZero: asBool(thresholds.hideArmorAtZero, base.thresholds.hideArmorAtZero),
      hideNeedsWhenFull: asBool(thresholds.hideNeedsWhenFull, base.thresholds.hideNeedsWhenFull),
      needsFullAt: clamp(Number(thresholds.needsFullAt), 80, 100, base.thresholds.needsFullAt),
    },
    vehicle: {
      units: vehicle.units === 'kph' ? 'kph' : 'mph',
      speedStyle: pick(vehicle.speedStyle, SPEED_STYLES, base.vehicle.speedStyle),
      showGear: asBool(vehicle.showGear, base.vehicle.showGear),
      showFuel: asBool(vehicle.showFuel, base.vehicle.showFuel),
      showEngine: asBool(vehicle.showEngine, base.vehicle.showEngine),
      showCruise: asBool(vehicle.showCruise, base.vehicle.showCruise),
      readoutBackground: asBool(vehicle.readoutBackground, base.vehicle.readoutBackground),
      minimapShape: pick(vehicle.minimapShape, MINIMAP_SHAPES, base.vehicle.minimapShape),
    },
  }
  return next
}

export function applyThemeVars(theme: Theme) {
  const root = document.documentElement
  root.style.setProperty('--accent', theme.accent)
  root.style.setProperty('--surface', theme.surface)
  root.style.setProperty('--surface-strong', theme.surfaceStrong)
  root.style.setProperty('--text', theme.text)
  root.style.setProperty('--muted', theme.muted)
  root.style.setProperty('--warning', theme.warning)
  root.style.setProperty('--critical', theme.critical)
  root.style.setProperty('--blur', `${theme.blur}px`)
  root.style.setProperty('--radius', `${theme.radius}px`)
  root.style.setProperty('--status-size', String(theme.statusSize))
  root.style.setProperty('--offset-x', `${theme.status.offsetX}vh`)
  root.style.setProperty('--offset-y', `${theme.status.offsetY}vh`)
  root.style.setProperty('--compass-offset-x', `${theme.compass.offsetX}vh`)
  root.style.setProperty('--compass-offset-y', `${theme.compass.offsetY}vh`)
  root.style.setProperty('--identity-offset-x', `${theme.identity.offsetX}vh`)
  root.style.setProperty('--identity-offset-y', `${theme.identity.offsetY}vh`)
  const circleMap = theme.vehicle.minimapShape === 'circle'
  root.style.setProperty('--map-w', circleMap ? '18.4vh' : '29.2vh')
  root.style.setProperty('--map-h', '18.4vh')
  root.style.setProperty('--map-radius', circleMap ? '50%' : `calc(${theme.radius}px * 0.85)`)
}

export function themeVisible(theme: Theme, key: keyof Theme['visibility']) {
  return theme.visibility[key] !== false
}

export function shouldShowCoreStat(
  theme: Theme,
  stat: 'armor' | 'hunger' | 'thirst',
  value: number,
) {
  const rules = theme.thresholds
  if (stat === 'armor' && rules.hideArmorAtZero !== false && value <= 0) {
    return false
  }
  if ((stat === 'hunger' || stat === 'thirst') && rules.hideNeedsWhenFull !== false) {
    const fullAt = rules.needsFullAt ?? 95
    if (value >= fullAt) {
      return false
    }
  }
  return true
}

export function voiceModeLabel(mode: number) {
  if (mode === 1) return 'WHISPER'
  if (mode === 3) return 'SHOUT'
  return 'NORMAL'
}

export function formatWaypointDistance(meters: number) {
  if (meters >= 1000) {
    return `${(meters / 1000).toFixed(1)}km`
  }
  return `${Math.round(meters)}m`
}
