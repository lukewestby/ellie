const start = (app) => {
  const preventNavigation = (e) => {
    e.returnValue = 'You have unsaved work. Are you sure you want to go?'
  }

  app.ports.pagesEditorEffectsStateOut.subscribe(({ tag, contents }) => {
    switch (tag) {
      case 'OpenInNewTab':
        window.open(contents, '_blank')
        break

      case 'SaveToken':
        const token = contents
        localStorage.setItem('Pages.Editor.token', token)
        break

      case 'ReloadIframe':
        requestAnimationFrame(() => {
          const output = document.querySelector('ellie-pages-editor-views-output')
          if (output) output.reload()
        })
        break

      case 'EnableNavigationCheck':
        const enabled = contents
        if (enabled) window.addEventListener('beforeunload', preventNavigation)
        else window.removeEventListener('beforeunload', preventNavigation)
        break

      case 'DownloadZip':
        const [project, elm, html] = contents
        import('jszip').then(JSZip => {
          const zip = new JSZip()
          zip.file('Main.elm', elm)
          zip.file('index.html', html)
          zip.file('elm.json', project)
          zip.generateAsync({ type: 'blob' }).then(blob => {
            const url = URL.createObjectURL(blob)
            const a = document.createElement('a')
            a.href = url
            a.download = 'ellie.zip'
            a.click()
            URL.revokeObjectURL(url)
          })
        })
        break

      case 'MoveElmCursor':
        const editor = document.getElementById('elm')
        if (!editor) break
        const [line, column] = contents
        editor.moveCursor(line, column)
        break

      default:
        break
    }
  })
}

export default { start }
