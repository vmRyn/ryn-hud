import { onUnmounted, ref, watch } from 'vue'

export function useDropPulse(
  source: () => number,
  options?: {
    threshold?: number
    ms?: number
    enabled?: () => boolean
  },
) {
  const active = ref(false)
  let timer = 0
  const threshold = options?.threshold ?? 2.5
  const ms = options?.ms ?? 580

  watch(source, (next, prev) => {
    if (options?.enabled && !options.enabled()) return
    if (typeof prev !== 'number' || next > prev - threshold) return
    active.value = false
    requestAnimationFrame(() => {
      active.value = true
    })
    window.clearTimeout(timer)
    timer = window.setTimeout(() => {
      active.value = false
    }, ms)
  })

  onUnmounted(() => window.clearTimeout(timer))
  return active
}
