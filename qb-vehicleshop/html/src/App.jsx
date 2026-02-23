import React, { useState, useCallback } from 'react';
import { AnimatePresence } from 'framer-motion';
import { useNuiEvent, useVisibility, useEscapeKey } from './hooks/useNuiEvent';
import { fetchNui, debugLog } from './utils/misc';
import VehicleCard from './components/VehicleCard';
import CategoryGrid from './components/CategoryGrid';
import VehicleGrid from './components/VehicleGrid';
import FinanceModal from './components/FinanceModal';
import TestDriveOverlay from './components/TestDriveOverlay';
import './index.css';

function App() {
  const [currentView, setCurrentView] = useState(null); // 'vehicle', 'categories', 'vehicles', 'finance'
  const [currentVehicle, setCurrentVehicle] = useState(null);
  const [categories, setCategories] = useState([]);
  const [vehicles, setVehicles] = useState([]);
  const [config, setConfig] = useState({});
  const [testDriveActive, setTestDriveActive] = useState(false);
  const [testDriveTime, setTestDriveTime] = useState('0:00');

  const visible = useVisibility();

  // Handle ESC key to close UI
  useEscapeKey(() => {
    if (visible && !testDriveActive) {
      handleClose();
    }
  });

  // Close the UI
  const handleClose = useCallback(() => {
    setCurrentView(null);
    setCurrentVehicle(null);
    fetchNui('closeUI');
  }, []);

  // Listen for NUI events
  useNuiEvent('openVehicleMenu', (data) => {
    debugLog('Opening vehicle menu', data);
    setCurrentVehicle(data.vehicle);
    setConfig(data.config || {});
    setCurrentView('vehicle');
  });

  useNuiEvent('openCategoryMenu', (data) => {
    debugLog('Opening category menu', data);
    setCategories(data.categories || []);
    setCurrentView('categories');
  });

  useNuiEvent('openVehicleList', (data) => {
    debugLog('Opening vehicle list', data);
    setVehicles(data.vehicles || []);
    setCurrentView('vehicles');
  });

  useNuiEvent('openFinanceMenu', (data) => {
    debugLog('Opening finance menu', data);
    setCurrentVehicle(data.vehicle);
    setConfig(data.config || {});
    setCurrentView('finance');
  });

  useNuiEvent('startTestDrive', (data) => {
    debugLog('Starting test drive', data);
    setTestDriveActive(true);
    setCurrentView(null);
  });

  useNuiEvent('updateTestDriveTime', (data) => {
    setTestDriveTime(data.time || '0:00');
  });

  useNuiEvent('endTestDrive', () => {
    setTestDriveActive(false);
  });

  // Handle actions
  const handleTestDrive = useCallback(() => {
    fetchNui('testDrive', { vehicle: currentVehicle });
    setCurrentView(null);
  }, [currentVehicle]);

  const handleBuy = useCallback(() => {
    fetchNui('buyVehicle', { vehicle: currentVehicle });
    handleClose();
  }, [currentVehicle, handleClose]);

  const handleFinance = useCallback(() => {
    setCurrentView('finance');
  }, []);

  const handleSwap = useCallback(() => {
    fetchNui('swapVehicle', {});
    setCurrentView(null);
  }, []);

  const handleCategorySelect = useCallback((category) => {
    fetchNui('selectCategory', { category });
    setCurrentView(null);
  }, []);

  const handleVehicleSelect = useCallback((vehicle) => {
    fetchNui('selectVehicle', { vehicle });
    setCurrentView(null);
  }, []);

  const handleFinanceSubmit = useCallback((financeData) => {
    fetchNui('financeVehicle', { 
      vehicle: currentVehicle,
      ...financeData 
    });
    handleClose();
  }, [currentVehicle, handleClose]);

  const handleReturnTestDrive = useCallback(() => {
    fetchNui('returnTestDrive');
    setTestDriveActive(false);
  }, []);

  if (!visible && !testDriveActive) {
    return null;
  }

  return (
    <div className="w-screen h-screen pointer-events-none">
      <AnimatePresence>
        {/* Test Drive Overlay */}
        {testDriveActive && (
          <TestDriveOverlay 
            timeRemaining={testDriveTime}
            onReturn={handleReturnTestDrive}
          />
        )}

        {/* Vehicle Card */}
        {currentView === 'vehicle' && currentVehicle && (
          <div className="w-full h-full flex items-center justify-start pl-4 pointer-events-auto">
            <VehicleCard
              vehicle={currentVehicle}
              onTestDrive={handleTestDrive}
              onBuy={handleBuy}
              onFinance={handleFinance}
              onSwap={handleSwap}
            />
          </div>
        )}

        {/* Category Grid */}
        {currentView === 'categories' && (
          <div className="pointer-events-auto">
            <CategoryGrid
              categories={categories}
              onSelect={handleCategorySelect}
              onClose={handleClose}
              onBack={() => setCurrentView('vehicle')}
            />
          </div>
        )}

        {/* Vehicle Grid */}
        {currentView === 'vehicles' && (
          <div className="pointer-events-auto">
            <VehicleGrid
              vehicles={vehicles}
              onSelect={handleVehicleSelect}
              onClose={handleClose}
              onBack={() => setCurrentView('categories')}
            />
          </div>
        )}

        {/* Finance Modal */}
        {currentView === 'finance' && currentVehicle && (
          <div className="pointer-events-auto">
            <FinanceModal
              vehicle={currentVehicle}
              config={config}
              onSubmit={handleFinanceSubmit}
              onClose={() => setCurrentView('vehicle')}
              onBack={() => setCurrentView('vehicle')}
            />
          </div>
        )}
      </AnimatePresence>
    </div>
  );
}

export default App;
