export type Remotes = {
  RequestInteract: RemoteEvent,
  RequestTurn: RemoteEvent,
  QuestStateUpdated: RemoteEvent,
  ShowToast: RemoteEvent,
  ShowAgeSplash: RemoteEvent,
  PlayerStatsUpdated: RemoteEvent,
}

export type QuestState = {
  questId: string,
  stage: number,
  swingPushes: number,
  spinTime: number,
}

return {}
