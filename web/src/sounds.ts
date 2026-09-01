const SOUNDS: Record<string, string> = {
  seatbeltOn: './sounds/seatbeltOn.mp3',
  seatbeltOff: './sounds/seatbeltOff.mp3',
}

const players = new Map<string, HTMLAudioElement>()

function player(id: string) {
  const src = SOUNDS[id]
  if (!src) return null
  let audio = players.get(id)
  if (!audio) {
    audio = new Audio(src)
    audio.preload = 'auto'
    players.set(id, audio)
  }
  return audio
}

export function playHudSound(id: string, volume = 0.45) {
  const audio = player(id)
  if (!audio) return
  audio.volume = Math.min(1, Math.max(0, volume))
  audio.currentTime = 0
  void audio.play().catch(() => {})
}
