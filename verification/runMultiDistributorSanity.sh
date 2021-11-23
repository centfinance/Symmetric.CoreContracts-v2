certoraRun pkg/distributors/contracts/MultiDistributor.sol \
  --verify MultiDistributor:verification/sanity.spec \
  --solc solc7.6 \
  --settings -t=300 \
  --staging \
  --msg "SchedulerHarness sanity"