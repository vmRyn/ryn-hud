export function isBrowserPreview() {
  try {
    return typeof GetParentResourceName !== 'function'
  } catch {
    return true
  }
}

type BrowserNuiHandler = (event: string, data: unknown) => unknown

let browserHandler: BrowserNuiHandler | null = null

export function setBrowserNuiHandler(handler: BrowserNuiHandler | null) {
  browserHandler = handler
}

export function getResourceName() {
  try {
    if (typeof GetParentResourceName === 'function') {
      return GetParentResourceName()
    }
  } catch {
    /* browser preview */
  }
  return 'ryn-hud'
}

export async function nuiPost<T = unknown>(event: string, data: unknown = {}): Promise<T | null> {
  if (isBrowserPreview()) {
    const result = browserHandler?.(event, data)
    return (result ?? { ok: true }) as T
  }

  try {
    const response = await fetch(`https://${getResourceName()}/${event}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data),
    })
    const text = await response.text()
    if (!text) {
      return { ok: true } as T
    }
    return JSON.parse(text) as T
  } catch {
    return null
  }
}
