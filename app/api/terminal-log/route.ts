// app/api/terminal-log/route.ts
import { NextRequest, NextResponse } from 'next/server';

export async function POST(request: NextRequest) {
  try {
    const { formatted, raw } = await request.json();
    
    // In log ra terminal PowerShell với màu sắc
    const colorCodes = {
      INFO: '\x1b[34m',      // Blue
      SUCCESS: '\x1b[32m',   // Green
      WARN: '\x1b[33m',      // Yellow
      ERROR: '\x1b[31m',     // Red
      DEBUG: '\x1b[35m',     // Magenta
      RESET: '\x1b[0m'       // Reset
    };

    const level = raw.level as keyof typeof colorCodes;
    const colorCode = colorCodes[level] || '';
    const resetCode = colorCodes.RESET;
    
    // In ra terminal với màu sắc
    console.log(`${colorCode}${formatted}${resetCode}`);
    
    // Cũng có thể ghi vào file log nếu cần
    // await writeToLogFile(formatted);
    
    return NextResponse.json({ success: true });
  } catch (error) {
    console.error('❌ Terminal logging error:', error);
    return NextResponse.json({ error: 'Logging failed' }, { status: 500 });
  }
}
