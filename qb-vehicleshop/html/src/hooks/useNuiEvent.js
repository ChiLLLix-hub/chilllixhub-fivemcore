import { useEffect, useState } from 'react';
import { isEnvBrowser, debugLog } from '../utils/misc';

// Hook to listen to NUI messages
export const useNuiEvent = (action, handler) => {
  useEffect(() => {
    const eventListener = (event) => {
      if (event.data.action === action) {
        debugLog(`NUI Event received: ${action}`, event.data);
        handler(event.data);
      }
    };

    window.addEventListener('message', eventListener);

    return () => window.removeEventListener('message', eventListener);
  }, [action, handler]);
};

// Hook to handle visibility state
export const useVisibility = () => {
  const [visible, setVisible] = useState(isEnvBrowser());

  useNuiEvent('setVisible', (data) => {
    setVisible(data.visible);
  });

  return visible;
};

// Hook to handle ESC key for closing
export const useEscapeKey = (onEscape) => {
  useEffect(() => {
    const handleKeyDown = (event) => {
      if (event.key === 'Escape') {
        onEscape();
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [onEscape]);
};
