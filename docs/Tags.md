# Tags

Single source of truth: `src/Shared/Tags.luau`.

## Tag List
- Interactable: Objek yang bisa di-interact (tekan E).
- Enemy: Musuh / dummy target.
- Loot: Pickup / drop item.
- SpawnPoint: Titik spawn (opsional).

## Rules
- Server/Studio owns tags. Client hanya read (CollectionService:GetTagged / signals).
- Jangan menambah tag dari client. Tag client bisa ketimpa saat server mengubah tag.

## Studio Workflow
1) Pilih Part/Model di Workspace.
2) Buka Tag Editor (CollectionService) dan tambah tag yang sesuai.
3) Simpan place. Tag akan tersimpan dan replicate ke client.

## Runtime
- Server dapat menambah/menghapus tag via `TagService:Tag` dan `TagService:Untag`.
- Client observe tag via `TagObserverController`.
