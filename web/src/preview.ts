import { defaultState, type HudState } from './types'

export const THEME_STORAGE_KEY = 'ryn-hud:preview-theme-v3'

export const PREVIEW_BACKGROUND_URL =
  'https://www.igta5.com/images/official-screenshot-pc-alamo-sea.jpg'

export function createMockState(): HudState {
  const state = JSON.parse(JSON.stringify(defaultState)) as HudState
  state.health = 86
  state.armor = 42
  state.hunger = 71
  state.thirst = 64
  state.stress = 18
  state.identity = {
    job: 'Mechanic',
    cash: 2450,
    bank: 18420,
    peek: false,
    showMoney: false,
    showJob: false,
  }
  state.compass = {
    heading: 312,
    cardinal: 'NW',
    street: 'Power St',
    crossing: 'Elgin Ave',
    zone: 'Downtown',
    waypoint: null,
  }
  state.vehicle = {
    active: false,
    speed: 0,
    rpm: 0,
    gear: '1',
    fuel: 68,
    engine: 92,
    fuelKind: 'petrol',
    seatbelt: false,
    seatbeltVisible: true,
    cruise: false,
    airborne: false,
    altitude: 0,
    heading: 0,
  }
  return state
}

export const mockScenarios: Record<string, Partial<HudState>> = {
  healthy: {
    health: 100,
    armor: 100,
    hunger: 100,
    thirst: 100,
    stress: 8,
  },
  critical: {
    health: 12,
    armor: 0,
    hunger: 18,
    thirst: 11,
    stress: 88,
  },
  combat: {
    health: 54,
    armor: 20,
    weapon: { show: true, clip: 12, reserve: 228, hasAmmo: true, label: 'AP Pistol', fireMode: 'Auto' },
    voice: { talking: true, mode: 2, radio: true },
  },
}
