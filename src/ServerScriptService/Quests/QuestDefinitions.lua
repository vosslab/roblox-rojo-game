local QuestDefinitions = {
  Q1_PLAYGROUND = {
    id = "Q1_PLAYGROUND",
    age = 5,
    stages = {
      {
        objective = "Go to the swings and push 10 times.",
        targetName = "SwingArea",
        swingGoal = 10,
      },
      {
        objective = "Ride the merry-go-round and keep spinning.",
        targetName = "MerryGoRoundBase",
        spinGoal = 20,
      },
      {
        objective = "Quest complete!",
        targetName = "",
      },
    },
  },
}

return QuestDefinitions
