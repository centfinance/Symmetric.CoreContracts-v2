certoraRun pkg/distributors/contracts/RewardsScheduler.sol \
  --verify RewardsScheduler:verification/sanity.spec \
  --solc solc7.6 \
  --settings -t=300 \
  --staging \
  --msg "SchedulerHarness sanity"