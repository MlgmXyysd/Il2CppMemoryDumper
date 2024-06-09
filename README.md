# Il2CppMemoryDumper

Dump Il2Cpp unprotected executable ELF and metadata from process memory

## Features

- Pure shell implementation
- Supports detection of ELF file headers
- Supports detection of Il2Cpp metadata file headers
- Supports guessing which is the correct ELF based on memory location
- Supports automatic memory region merging
- Supports dumping Il2Cpp metadata from memory
- Supports dumping decrypted Il2Cpp metadata from memory
- Supports ELF file headers analysis
- Supports Il2Cpp metadata file headers analysis

## Usage

- Android Shell (root):

```
Il2CppMemoryDumper.sh <package> [output=/sdcard/dump]
```

- Output will be:
```
[output]/[startOffset]_[package]_[memoryName].[so/bin/dat]
[output]/[package]_maps.txt
```

## To-Dos

- Nothing to do

## Workaround

- [My Blog](https://www.neko.ink/2023/10/15/dump-il2cpp-executable-from-memory/)
- [52Pojie](https://www.52pojie.cn/thread-1844587-1-1.html)

## What's the next step?

- Check the version of Il2Cpp metadata. Since `IL2CPP_ASSERT` is not valid for Release versions, some games may scramble the metadata version, which can cause a failure to dump.
- Fix dumped ELF using [SoFixer](https://github.com/F8LEFT/SoFixer) (or other repair methods).
- Dump Method and StringLiteral using [Il2CppDumper](https://github.com/MlgmXyysd/Il2CppDumper-Standalone). It contains the latest source code compilation (supporting IL2CPP 29), you also can download standalone execueable for Linux (x64, arm, arm64), MacOS (x64, arm64), WoA (arm, arm64) in it.

## License

No license, you are only allowed to use this project. All rights are reserved by [NekoYuzu (MlgmXyysd)](https://github.com/MlgmXyysd).
