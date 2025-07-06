# .github Directory

Thư mục này chứa các file cấu hình cho GitHub và GitHub Copilot.

## Files:

### `copilot-instructions.md`
- **Mục đích**: Cung cấp context và coding guidelines cho GitHub Copilot
- **Tác dụng**: Đảm bảo Copilot luôn generate code theo standards của project
- **Nội dung**: 
  - TypeScript strict rules
  - React/Next.js 15 patterns
  - Error handling standards
  - Project-specific context
  - ESLint compliance rules

### Tại sao đặt trong `.github`?
- GitHub Copilot tự động đọc file này khi chat/suggest code
- Đảm bảo consistency trong codebase
- Giúp Copilot hiểu context của project (Next.js 15 + Supabase + Vietnamese POS system)
- Tuân thủ best practices của GitHub

## Cách sử dụng:
1. File sẽ tự động được Copilot đọc khi bạn chat hoặc code
2. Không cần import hay reference manual
3. Mọi suggestion từ Copilot sẽ follow rules trong file này
4. Update file này khi có thay đổi về coding standards

## Lưu ý:
- File này chỉ tác động đến GitHub Copilot
- Không ảnh hưởng đến build process hay runtime
- Nên keep file này updated với latest project standards
