1. 修改 `Sconscript` 文件时，不仅要添加 `Source` 语句，还需要在上方 `SimObject` 中追加 `NMRURP`， 否则会有报错：
    ```
    build/X86/mem/cache/replacement_policies/nmru_rp.cc:35:10: fatal error: params/NMRURP.hh: No such file or directory
   35 | #include "params/NMRURP.hh"
      |          ^~~~~~~~~~~~~~~~~~
    compilation terminated.
    [SO Param] m5.objects.Prefetcher, AccessMapPatternMatching -> X86/params/AccessMapPatternMatching.hh
    scons: *** [build/X86/mem/cache/replacement_policies/nmru_rp.do] Error 1
    scons: building terminated because of errors.
    ```