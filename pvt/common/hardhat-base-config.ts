type ContractSettings = Record<
  string,
  {
    version: string;
    runs: number;
  }
>;

const contractSettings: ContractSettings = {
  '@balancer-labs/v2-vault/contracts/Vault.sol': {
    version: '0.7.6',
    runs: 1500,
  },
  '@balancer-labs/v2-pool-weighted/contracts/WeightedPool2TokensFactory.sol': {
    version: '0.7.6',
    runs: 200,
  },
  '@balancer-labs/v2-pool-weighted/contracts/LiquidityBootstrappingPoolFactory.sol': {
    version: '0.7.6',
    runs: 200,
  },
  '@balancer-labs/v2-pool-stable/contracts/meta/MetaStablePool.sol': {
    version: '0.7.6',
    runs: 200,
  },
  '@balancer-labs/v2-pool-stable/contracts/meta/MetaStablePoolFactory.sol': {
    version: '0.7.6',
    runs: 200,
  },
};

type SolcConfig = {
  version: string;
  settings: {
    optimizer: {
      enabled: boolean;
      runs?: number;
    },
    evmVersion: string,
    metadata: {
      useLiteralContent: boolean;
    },
    outputSelection: any;
  };
};

export const compilers: [SolcConfig] = [
  {
    version: '0.7.6',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      evmVersion: 'istanbul',
      metadata: {
        useLiteralContent: true
      },
      outputSelection: {
        '*': {
          '*':
          [
            'abi',
            'evm.bytecode',
            'evm.deployedBytecode',
            'evm.methodIdentifiers',
            'metadata'
          ],
          '':
          [
            'ast'
          ]
        }
      }
    },
  },
];

export const overrides = (packageName: string): Record<string, SolcConfig> => {
  const overrides: Record<string, SolcConfig> = {};

  for (const contract of Object.keys(contractSettings)) {
    overrides[contract.replace(`${packageName}/`, '')] = {
      version: contractSettings[contract].version,
      settings: {
        optimizer: {
          enabled: true,
          runs: contractSettings[contract].runs,
        },
        evmVersion: 'istanbul',
        metadata: {
          useLiteralContent: true
        },
        outputSelection: {
          '*': {
            '*':
            [
              'abi',
              'evm.bytecode',
              'evm.deployedBytecode',
              'evm.methodIdentifiers',
              'metadata',
              'devdoc',
              'userdoc',
              'storageLayout',
              'evm.methodIdentifiers',
              'evm.gasEstimates'
            ],
            '':
            [
              'ast'
            ]
          }
        }
      },
    };
  }

  return overrides;
};
