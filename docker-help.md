docker run -v /Users/veshen/Documents/solidity:/sources ethereum/solc:stable -o /sources/output --abi --bin /sources/dynamicArray.sol

solc, the Solidity commandline compiler.

This program comes with ABSOLUTELY NO WARRANTY. This is free software, and you
are welcome to redistribute it under certain conditions. See 'solc --license'
for details.

Usage: solc [options] [input_file...]
Compiles the given Solidity input files (or the standard input if none given or
"-" is used as a file name) and outputs the components specified in the options
at standard output or in files in the output directory, if specified.
Imports are automatically read from the filesystem, but it is also possible to
remap paths using the context:prefix=path syntax.
Example:
solc --bin -o /tmp/solcoutput dapp-bin=/usr/local/lib/dapp-bin contract.sol

General Information:
  --help               Show help message and exit.
  --version            Show version and exit.
  --license            Show licensing information and exit.

Input Options:
  --base-path path     Use the given path as the root of the source tree 
                       instead of the root of the filesystem.
  --allow-paths path(s)
                       Allow a given path for imports. A list of paths can be 
                       supplied by separating them with a comma.
  --ignore-missing     Ignore missing files.
  --error-recovery     Enables additional parser error recovery.

Output Options:
  -o [ --output-dir ] path
                       If given, creates one file per component and 
                       contract/file at the specified directory.
  --overwrite          Overwrite existing files (used together with -o).
  --evm-version version (=london)
                       Select desired EVM version. Either homestead, 
                       tangerineWhistle, spuriousDragon, byzantium, 
                       constantinople, petersburg, istanbul, berlin or london.
  --experimental-via-ir 
                       Turn on experimental compilation mode via the IR 
                       (EXPERIMENTAL).
  --revert-strings debug,default,strip,verboseDebug
                       Strip revert (and require) reason strings or add 
                       additional debugging information.
  --stop-after stage   Stop execution after the given compiler stage. Valid 
                       options: "parsing".

Alternative Input Modes:
  --standard-json      Switch to Standard JSON input / output mode, ignoring 
                       all options. It reads from standard input, if no input 
                       file was given, otherwise it reads from the provided 
                       input file. The result will be written to standard 
                       output.
  --link               Switch to linker mode, ignoring all options apart from 
                       --libraries and modify binaries in place.
  --assemble           Switch to assembly mode, ignoring all options except 
                       --machine, --yul-dialect, --optimize and 
                       --yul-optimizations and assumes input is assembly.
  --yul                Switch to Yul mode, ignoring all options except 
                       --machine, --yul-dialect, --optimize and 
                       --yul-optimizations and assumes input is Yul.
  --strict-assembly    Switch to strict assembly mode, ignoring all options 
                       except --machine, --yul-dialect, --optimize and 
                       --yul-optimizations and assumes input is strict 
                       assembly.
  --import-ast         Import ASTs to be compiled, assumes input holds the AST 
                       in compact JSON format. Supported Inputs is the output 
                       of the --standard-json or the one produced by 
                       --combined-json ast,compact-format

Assembly Mode Options:
  --machine evm,ewasm  Target machine in assembly or Yul mode.
  --yul-dialect evm,ewasm
                       Input dialect to use in assembly or yul mode.

Linker Mode Options:
  --libraries libs     Direct string or file containing library addresses. 
                       Syntax: <libraryName>=<address> [, or whitespace] ...
                       Address is interpreted as a hex string prefixed by 0x.

Output Formatting:
  --pretty-json        Output JSON in pretty format.
  --json-indent N (=2) Indent pretty-printed JSON with N spaces. Enables 
                       '--pretty-json' automatically.
  --color              Force colored output.
  --no-color           Explicitly disable colored output, disabling terminal 
                       auto-detection.
  --error-codes        Output error codes.

Output Components:
  --ast-compact-json   AST of all source files in a compact JSON format.
  --asm                EVM assembly of the contracts.
  --asm-json           EVM assembly of the contracts in JSON format.
  --opcodes            Opcodes of the contracts.
  --bin                Binary of the contracts in hex.
  --bin-runtime        Binary of the runtime part of the contracts in hex.
  --abi                ABI specification of the contracts.
  --ir                 Intermediate Representation (IR) of all contracts 
                       (EXPERIMENTAL).
  --ir-optimized       Optimized intermediate Representation (IR) of all 
                       contracts (EXPERIMENTAL).
  --ewasm              Ewasm text representation of all contracts 
                       (EXPERIMENTAL).
  --hashes             Function signature hashes of the contracts.
  --userdoc            Natspec user documentation of all contracts.
  --devdoc             Natspec developer documentation of all contracts.
  --metadata           Combined Metadata JSON whose Swarm hash is stored 
                       on-chain.
  --storage-layout     Slots, offsets and types of the contract's state 
                       variables.

Extra Output:
  --gas                Print an estimate of the maximal gas usage for each 
                       function.
  --combined-json abi,asm,ast,bin,bin-runtime,compact-format,devdoc,function-debug,function-debug-runtime,generated-sources,generated-sources-runtime,hashes,interface,metadata,opcodes,srcmap,srcmap-runtime,storage-layout,userdoc
                       Output a single json document containing the specified 
                       information.

Metadata Options:
  --metadata-hash ipfs,none,swarm
                       Choose hash method for the bytecode metadata or disable 
                       it.
  --metadata-literal   Store referenced sources as literal data in the metadata
                       output.

Optimizer Options:
  --optimize           Enable bytecode optimizer.
  --optimize-runs n (=200)
                       Set for how many contract runs to optimize. Lower values
                       will optimize more for initial deployment cost, higher 
                       values will optimize more for high-frequency usage.
  --optimize-yul       Legacy option, ignored. Use the general --optimize to 
                       enable Yul optimizer.
  --no-optimize-yul    Disable Yul optimizer in Solidity.
  --yul-optimizations steps
                       Forces yul optimizer to use the specified sequence of 
                       optimization steps instead of the built-in one.

Model Checker Options:
  --model-checker-contracts default,<source>:<contract> (=default)
                       Select which contracts should be analyzed using the form
                       <source>:<contract>.Multiple pairs <source>:<contract> 
                       can be selected at the same time, separated by a comma 
                       and no spaces.
  --model-checker-div-mod-no-slacks 
                       Encode division and modulo operations with their precise
                       operators instead of multiplication with slack 
                       variables.
  --model-checker-engine all,bmc,chc,none (=none)
                       Select model checker engine.
  --model-checker-show-unproved 
                       Show all unproved targets separately.
  --model-checker-solvers all,cvc4,z3,smtlib2 (=all)
                       Select model checker solvers.
  --model-checker-targets default,all,constantCondition,underflow,overflow,divByZero,balance,assert,popEmptyArray,outOfBounds (=default)
                       Select model checker verification targets. Multiple 
                       targets can be selected at the same time, separated by a
                       comma and no spaces. By default all targets except 
                       underflow and overflow are selected.
  --model-checker-timeout ms
                       Set model checker timeout per query in milliseconds. The
                       default is a deterministic resource limit. A timeout of 
                       0 means no resource/time restrictions for any query.