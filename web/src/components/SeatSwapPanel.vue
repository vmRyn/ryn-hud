<script setup lang="ts">
import { computed } from 'vue'

export interface SeatSwapSeat {
  index: number
  label: string
  occupied: boolean
  current: boolean
  row: number
  col: number
}

export interface SeatSwapPayload {
  seats: SeatSwapSeat[]
  seatCount: number
  layout: 'grid' | 'stacked'
  title?: string
  hint?: string
}

const props = defineProps<{
  open: boolean
  data: SeatSwapPayload | null
}>()

const emit = defineEmits<{
  close: []
  select: [index: number]
}>()

const rows = computed(() => {
  const seats = props.data?.seats || []
  const maxRow = seats.reduce((m, s) => Math.max(m, s.row), 0)
  const grouped: SeatSwapSeat[][] = []
  for (let r = 0; r <= maxRow; r++) {
    grouped.push(
      seats
        .filter((s) => s.row === r)
        .sort((a, b) => a.col - b.col),
    )
  }
  return grouped
})

const title = computed(() => props.data?.title || 'Change seat')
const hint = computed(() => props.data?.hint || 'Select an empty seat')
const stacked = computed(() => props.data?.layout === 'stacked')

function onSelect(seat: SeatSwapSeat) {
  if (seat.occupied || seat.current) return
  emit('select', seat.index)
}
</script>

<template>
  <Transition name="seatswap">
    <div v-if="open && data" class="seatswap" role="dialog" aria-modal="true" :aria-label="title">
      <button type="button" class="seatswap-backdrop" aria-label="Close" @click="emit('close')" />
      <div class="seatswap-panel">
        <header class="seatswap-head">
          <h2>{{ title }}</h2>
          <p>{{ hint }}</p>
        </header>
        <div class="seatswap-body" :class="{ stacked }">
          <div class="seatswap-cabin">
            <div
              v-for="(row, ri) in rows"
              :key="ri"
              class="seatswap-row"
              :class="{ solo: row.length === 1 }"
            >
              <button
                v-for="seat in row"
                :key="seat.index"
                type="button"
                class="seatswap-seat"
                :class="{
                  current: seat.current,
                  occupied: seat.occupied,
                  free: !seat.occupied && !seat.current,
                }"
                :disabled="seat.occupied || seat.current"
                :title="seat.label"
                @click="onSelect(seat)"
              >
                <span class="seatswap-seat-icon" aria-hidden="true">
                  <svg viewBox="0 0 24 24" fill="none">
                    <path
                      d="M7 4.5h10c.8 0 1.5.7 1.5 1.5v3.2c0 .4-.2.8-.5 1L16.5 12v5.5c0 .8-.7 1.5-1.5 1.5h-6c-.8 0-1.5-.7-1.5-1.5V12L6 10.2c-.3-.2-.5-.6-.5-1V6c0-.8.7-1.5 1.5-1.5Z"
                      stroke="currentColor"
                      stroke-width="1.5"
                      stroke-linejoin="round"
                    />
                    <path
                      d="M6 10.5h12"
                      stroke="currentColor"
                      stroke-width="1.5"
                      stroke-linecap="round"
                    />
                  </svg>
                </span>
                <span class="seatswap-seat-label">{{ seat.label }}</span>
                <span v-if="seat.current" class="seatswap-seat-tag">You</span>
                <span v-else-if="seat.occupied" class="seatswap-seat-tag">Taken</span>
              </button>
            </div>
          </div>
        </div>
        <footer class="seatswap-foot">
          <kbd>Esc</kbd>
          <span>Close</span>
        </footer>
      </div>
    </div>
  </Transition>
</template>
