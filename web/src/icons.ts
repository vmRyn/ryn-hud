import type { Component } from 'vue'
import {
  PhBroadcast,
  PhCheckCircle,
  PhCrosshair,
  PhDrop,
  PhForkKnife,
  PhGasPump,
  PhHeart,
  PhInfo,
  PhLightning,
  PhMicrophone,
  PhParachute,
  PhPulse,
  PhSeatbelt,
  PhShield,
  PhStar,
  PhWarningCircle,
  PhWaves,
  PhWind,
  PhXCircle,
} from '@phosphor-icons/vue'
import { ICON_NAMES } from './types'

export const ICON_OPTIONS = ICON_NAMES

export type IconName = (typeof ICON_OPTIONS)[number]

export const ICON_COMPONENTS: Record<string, Component> = {
  heart: PhHeart,
  shield: PhShield,
  utensils: PhForkKnife,
  droplet: PhDrop,
  activity: PhPulse,
  fuel: PhGasPump,
  seatbelt: PhSeatbelt,
  mic: PhMicrophone,
  wind: PhWind,
  waves: PhWaves,
  bolt: PhLightning,
  crosshair: PhCrosshair,
  star: PhStar,
  parachute: PhParachute,
  info: PhInfo,
  check: PhCheckCircle,
  warning: PhWarningCircle,
  x: PhXCircle,
  megaphone: PhBroadcast,
}

export function iconComponent(name: string) {
  return ICON_COMPONENTS[name] || PhHeart
}
