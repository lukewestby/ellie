import 'es6-promise/auto'
import './Main.css'
import CodeMirrorLoader from '../../Ellie/CodeMirror/Loader'
import fixHtml from './fixHtml'
import captureOpbeat from '../../Shared/Opbeat'
import CodeMirrorRunner from '../../Ellie/CodeMirror/Runner'
import AwsRunner from '../../Shared/Aws/Runner'
import IconLoader from '../../Ellie/Ui/Icon/Loader'
import '../../Ellie/Ui/ProgressBar.css'
import Layout from './Layout'

IconLoader.load()

CodeMirrorLoader
  .load()
  .then(CodeMirror => {
    const Elm = require('./Main.elm')

    let hasUnsavedWork = false;
    let previousLocation = window.location.pathname
    window.addEventListener('popstate', e => {
      if (hasUnsavedWork) {
        const result = window.confirm('You have unsaved work. Are you sure you want to go?')
        if (!result) {
          window.history.pushState({}, '', previousLocation)
          e.preventDefault()
        }
      }
    })

    const acceptedTermsVersion = JSON.parse(document.querySelector('meta[name=accepted_terms_version]').content)
    const latestTermsVersion = JSON.parse(document.querySelector('meta[name=latest_terms_version]').content)

    const app = Elm.Pages.Editor.Main.fullscreen({
      windowSize: {
        width: window.innerWidth,
        height: window.innerHeight
      },
      online: process.env.NODE_ENV === 'production' ? window.navigator.onLine : true,
      vimMode: localStorage.getItem('Pages.Editor.vimMode') === 'true',
      acceptedTermsVersion,
      latestTermsVersion,
    })

    app.ports.opbeatCaptureOut.subscribe(captureOpbeat)

    Layout.start(app)
    CodeMirrorRunner.start(CodeMirror, app)
    AwsRunner.start(app)

    app.ports.pathChangedOut.subscribe(() => {
      previousLocation = window.location.pathname
    })

    app.ports.hasUnsavedWork.subscribe(nextValue => {
      hasUnsavedWork = nextValue
    })

    app.ports.reloadIframeOut.subscribe(() => {
      var iframe = document.getElementById('results_iframe')
      if (!iframe) return
      iframe.src = iframe.src
    })

    app.ports.openDebuggerOut.subscribe(() => {
      var iframe = document.getElementById('results_iframe')
      if (!iframe) return
      iframe.contentWindow.postMessage({ type: 'debug' }, API_ORIGIN)
    })

    app.ports.openNewWindow.subscribe(url => {
      var win = window.open(url, '_blank')
      win.focus()
    })

    app.ports.saveVimMode.subscribe(enabled => {
      localStorage.setItem('Pages.Editor.vimMode', enabled)
    })

    window.addEventListener('online', function () {
      app.ports.online.send(true)
    })

    window.addEventListener('offline', function () {
      app.ports.online.send(false)
    })

    window.addEventListener('beforeunload', function (e) {
      if (hasUnsavedWork) {
        e.returnValue = 'You have unsaved work. Are you sure you want to go?'
      }
    })

    window.addEventListener('message', function (event) {
      if (event.data.type === 'error') {
        app.ports.jsError.send(event.data.message)
      }
    })


    import(/* webpackChunkName: "make-0.18.0" */'Make/0.18.0')
      .then(Compiler => {
        Compiler.start({
          onReport: console.log.bind(console),
          onReady: compile => {
            console.log(compile)
            app.ports.compileOnClientOut.subscribe(function ([html, elm, packages, forSave]) {
              compile({ source: elm, dependencies: packages })
            })
          }
        })



        // let workQueue = []
        // let runForSave, htmlCode

        // const readFile = (file) =>
        //   new Promise((resolve, reject) => {
        //     const fr = new FileReader()
        //     fr.addEventListener('load', () => {
        //       resolve(fr.result)
        //     })
        //     fr.addEventListener('error', () => {
        //       reject(fr.error)
        //     })
        //     fr.readAsText(file)
        //   })

        // const getSourceScript = (scriptFile) => {
        //   if (runForSave) {
        //     return readFile(scriptFile)
        //       .then(data => '<script>' + data + '</script>')
        //   } else {
        //     return Promise.resolve(`<script src=${URL.createObjectURL(scriptFile)}></script>`)
        //   }
        // }

        // const sendToPort = data => {
        //   runForSave ?
        //     app.ports.compileForSaveIn.send(data) :
        //     app.ports.compilerMessagesIn.send(data)
        // }

        // const callback = (data) => {
        //   workQueue.push(data)
        //   setTimeout(function work() {
        //     if (!workQueue.length) return
        //     var nextMessage = workQueue.shift()

        //     if (nextMessage.type === 'Success') {
        //       getSourceScript(nextMessage.url)
        //         .then(sourceScript => fixHtml({
        //           htmlCode,
        //           embedApi: !runForSave,
        //           sourceScript
        //         }))
        //         .then(htmlUrl => sendToPort({ type: 'Success', url: htmlUrl }))
        //         .catch(error => sendToPort({ type: 'Failed', message: error.message }))
        //     } else {
        //       sendToPort(nextMessage)
        //     }
        //     setTimeout(work)
        //   })
        // }

        // const compiler = Compiler.init(callback)

        // app.ports.clearElmStuffOut.subscribe(() => {
        //   compiler.clearElmStuff()
        // })

        // app.ports.compileOnClientOut.subscribe(function ([html, elm, packages, forSave]) {
        //   runForSave = forSave
        //   htmlCode = html
        //   compiler.compile({ elm, packages })
        // })
      })
  })
