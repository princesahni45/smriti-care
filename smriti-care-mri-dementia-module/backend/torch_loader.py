"""
Windows DLL loader helper for PyTorch.
Ensures Microsoft Visual C++ and OpenMP runtime DLLs are loaded in proper sequence.
"""
import sys
import os
import ctypes

if sys.platform == "win32":
    try:
        import site
        search_dirs = []
        try:
            search_dirs.extend(site.getsitepackages())
        except Exception:
            pass
        try:
            search_dirs.append(site.getusersitepackages())
        except Exception:
            pass
        for sp in search_dirs:
            torch_lib = os.path.join(sp, "torch", "lib")
            if os.path.isdir(torch_lib):
                try:
                    os.add_dll_directory(torch_lib)
                except Exception:
                    pass
                for dll in ['vcruntime140.dll', 'vcruntime140_1.dll', 'msvcp140.dll', 'libiomp5md.dll', 'c10.dll']:
                    dll_path = os.path.join(torch_lib, dll)
                    if os.path.exists(dll_path):
                        try:
                            ctypes.CDLL(dll_path)
                        except Exception:
                            pass
                break
    except Exception:
        pass
