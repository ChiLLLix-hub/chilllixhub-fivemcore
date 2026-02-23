import React from 'react';
import { motion } from 'framer-motion';

const TestDriveOverlay = ({ timeRemaining, onReturn }) => {
  return (
    <div className="fixed bottom-4 right-4 z-50 pointer-events-none">
      <motion.div
        initial={{ opacity: 0, y: 50 }}
        animate={{ opacity: 1, y: 0 }}
        exit={{ opacity: 0, y: 50 }}
        className="pointer-events-auto w-fit"
      >
        <div className="bg-black/70 backdrop-blur-sm rounded-lg px-4 py-3 shadow-2xl border border-white/10">
          <div className="flex flex-col gap-2">
            <div className="flex items-center gap-2">
              <svg className="w-4 h-4 text-yellow-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
              <span className="text-white font-semibold text-sm">Test Drive</span>
              <span className="text-lg font-bold text-primary-400 ml-2">{timeRemaining}</span>
            </div>
            
            <button
              onClick={onReturn}
              className="w-full bg-red-600 hover:bg-red-700 text-white font-semibold py-2 px-4 rounded-md transition-all duration-200 text-sm"
            >
              Stop Test Drive [E]
            </button>
          </div>
        </div>
      </motion.div>
    </div>
  );
};

export default TestDriveOverlay;
