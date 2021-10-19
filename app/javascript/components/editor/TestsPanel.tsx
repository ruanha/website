import React from 'react'
import { Tab } from '../common/Tab'
import { TabsContext } from '../Editor'
import { useHighlighting } from '../../utils/highlight'
import { TestFile } from '../types'

export const TestsPanel = ({
  tests,
  highlightjsLanguage,
}: {
  tests: readonly TestFile[]
  highlightjsLanguage: string
}): JSX.Element => {
  const ref = useHighlighting<HTMLDivElement>()

  return (
    <Tab.Panel
      id="tests"
      context={TabsContext}
      className="tests c-code-pane"
      ref={ref}
    >
      {tests.map((test) => {
        return (
          <pre key={test.filename}>
            <code
              className={highlightjsLanguage}
              data-highlight-line-numbers={true}
              data-highlight-line-number-start={1}
            >
              {test.content}
            </code>
          </pre>
        )
      })}
    </Tab.Panel>
  )
}
