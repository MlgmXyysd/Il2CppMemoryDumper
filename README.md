# Il2CppMemoryDumper

Dump Il2Cpp unprotected executable ELF from process memory

## Features

- Pure shell implementation
- Supports detection of ELF file headers
- Supports guessing which is the correct ELF based on memory location
- Supports automatic memory region merging
- Supports dumping `global-metadata.dat` from memory
- Supports ELF file headers analysis

## Usage

- Android Shell (root):

```
Il2CppMemoryDumper.sh <package> [output=/sdcard/dump]
```

- Output will be:
```
[output]/[startOffset]_[package]_[memoryName].[so/dump/dat]
[output]/[package]_maps.txt
```

## To-Dos

- Nothing to do

## Workaround

- [My Blog](https://www.neko.ink/2023/10/15/dump-il2cpp-executable-from-memory/)
- [52Pojie](https://www.52pojie.cn/thread-1844587-1-1.html)

## What's the next step?

- Fix dumped ELF using [SoFixer](https://github.com/F8LEFT/SoFixer)
- Dump Method and StringLiteral using [Il2CppDumper](https://github.com/Perfare/Il2CppDumper), you can download standalone execueable for Linux (x64, arm, arm64), MacOS (x64, arm64), WoA (arm, arm64) in [Il2CppDumper-Standalone](https://github.com/MlgmXyysd/Il2CppDumper-Standalone)

## Credits

- [NekoYuzu (MlgmXyysd)](https://github.com/MlgmXyysd)
