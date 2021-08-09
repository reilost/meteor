import Vue from 'vue';
import Vuex from 'vuex';
import VuexPersistence from 'vuex-persist';
import dayjs from 'dayjs';
const vuexLocal = new VuexPersistence({
  storage: window.localStorage,
  reducer: (state) => ({ txnList: state.txnList }),
});

Vue.use(Vuex);

const TXN_MAX_LEN = 10;
const HexToString = (hex) => hex.toString(16);

export default new Vuex.Store({
  state: {
    accountHash: '',
    txnList: {},
  },
  getters: {
    $accountHash: (state) => state.accountHash,
    $txnList: (state) => state.txnList[HexToString(state.accountHash)],
  },
  mutations: {
    UPDATE_ACCOUNT_HASH(state, payload) {
      state.accountHash = payload;
    },
    ADD_TXN(state, payload) {
      if (!Array.isArray(state.txnList[HexToString(state.accountHash)])) {
        state.txnList[HexToString(state.accountHash)] = [];
      }

      const len = state.txnList[HexToString(state.accountHash)].length;
      if (len >= TXN_MAX_LEN) {
        state.txnList[HexToString(state.accountHash)] = state.txnList[
          HexToString(state.accountHash)
        ].slice(0, TXN_MAX_LEN);
      }

      state.txnList[HexToString(state.accountHash)].unshift({
        txn: payload,
        time: dayjs().format('YYYY-MM-DD HH:mm:ss'),
      });
    },
    CLEAN_TXN(state) {
      state.txnList[HexToString(state.accountHash)] = [];
    },
  },
  actions: {
    $updateAccountHash({ commit }, payload) {
      commit('UPDATE_ACCOUNT_HASH', payload);
    },
    $addTxn({ commit }, payload) {
      commit('ADD_TXN', payload);
    },
    $cleanTxn({ commit }) {
      commit('CLEAN_TXN');
    },
  },
  plugins: [vuexLocal.plugin],
});
