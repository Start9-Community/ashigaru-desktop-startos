import { VersionGraph } from '@start9labs/start-sdk'
import { current } from './current'
import { v_1_4_5_0 } from './v1.4.5_0'

export const versionGraph = VersionGraph.of({
  current,
  other: [v_1_4_5_0],
})
