import { NextRequest, NextResponse } from 'next/server';

interface LogEntry {
  readonly level: string;
  readonly step: string;
  readonly message: string;
  readonly data?: string;
  readonly timestamp: string;
}

interface BatchLogRequest {
  readonly logs: readonly LogEntry[];
}

export async function POST(request: NextRequest): Promise<NextResponse> {
  try {
    const body = await request.json() as BatchLogRequest;
    
    if (!body.logs || !Array.isArray(body.logs)) {
      return NextResponse.json(
        { error: 'Invalid logs format' },
        { status: 400 }
      );
    }

    // Log each entry to console (can be extended to save to database)
    body.logs.forEach(log => {
      const emoji = getLevelEmoji(log.level);
      const timestamp = new Date(log.timestamp).toLocaleTimeString('vi-VN');
      
      console.log(
        `${emoji} [${timestamp}] ${log.step.toUpperCase()}: ${log.message}`,
        log.data || ''
      );
    });

    return NextResponse.json({ 
      success: true, 
      processed: body.logs.length 
    });

  } catch (error: unknown) {
    console.error('Batch log API error:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

function getLevelEmoji(level: string): string {
  switch (level.toLowerCase()) {
    case 'success': return '✅';
    case 'error': return '❌';
    case 'warn': return '⚠️';
    case 'debug': return '🔍';
    default: return '🔵';
  }
}
