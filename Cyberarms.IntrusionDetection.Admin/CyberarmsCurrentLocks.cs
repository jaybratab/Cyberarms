using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Drawing;
using System.Data;
using System.Linq;
using System.Text;
using System.Windows.Forms;
using Cyberarms.IntrusionDetection.Shared;

namespace Cyberarms.IntrusionDetection.Admin {
    public partial class CyberarmsCurrentLocks : UserControl {
        public CyberarmsCurrentLocks() {
            InitializeComponent();
        }


        private void actionMenu_MouseDown(object sender, MouseEventArgs e) {
            Control c = (Control)sender;
            c.Location = new Point(c.Location.X + 1, c.Location.Y + 1);
        }

        private void actionMenu_MouseUp(object sender, MouseEventArgs e) {
            Control c = (Control)sender;
            c.Location = new Point(c.Location.X - 1, c.Location.Y - 1);
        }

        public DataGridViewRow FindRow(int id) {
            foreach(DataGridViewRow row in dataGridViewLocks.Rows) {
                if(row.Cells[7].Value.ToString().Equals(id.ToString())){
                    return row;
                }
            }
            return null;
        }

        public void Clear() {
            dataGridViewLocks.Rows.Clear();
        }

        public void Add(int id, Image icon, string statusName, string clientIp, string displayName, DateTime lockDate, DateTime unlockDate, int status) {
            DataGridViewRow row = FindRow(id);
            if (row != null) {
                if (row.Cells[2].Value.ToString().Equals(status)) {
                    return;
                }
            } else {
                dataGridViewLocks.Rows.Insert(0, new DataGridViewRow());
                row = dataGridViewLocks.Rows[0];
            }
            (row.Cells[1] as DataGridViewImageCell).Value = icon;
            row.Cells[2].Value = statusName;
            row.Cells[3].Value = clientIp;
            row.Cells[4].Value = displayName;
            row.Cells[5].Value = lockDate;
            row.Cells[6].Value = unlockDate;
            row.Cells[7].Value = id.ToString();
            row.Cells[8].Value = status;
        }

        public void SetHardLocks(int number) {
            labelCurrentLocksHardLocks.Text = String.Format("{0} hard locks", number);

        }

        private void checkBoxSelectAllLocks_CheckedChanged(object sender, EventArgs e) {
            foreach (DataGridViewRow r in dataGridViewLocks.Rows) {
                DataGridViewCheckBoxCell c = (DataGridViewCheckBoxCell)r.Cells["dataGridViewSelectItem"];
                c.Value = (sender as CheckBox).Checked;
            }
        }


        public void SetSoftLocks(int number) {
            labelCurrentLocksSoftLocks.Text = String.Format("{0} soft locks", number);
        }

        private void actionMenuUnlock_Click(object sender, EventArgs e) {
            foreach (DataGridViewRow row in this.dataGridViewLocks.Rows) {
                DataGridViewCheckBoxCell c = (DataGridViewCheckBoxCell)row.Cells["dataGridViewSelectItem"];
                //if (c.Value == null) {
                //    if (c.Selected) { c.Value = c.TrueValue; } else { c.Value = c.FalseValue; }
                //}
                if ((bool)c.EditedFormattedValue == true && (row.Cells[8].Value.ToString() == Cyberarms.IntrusionDetection.Shared.Lock.LOCK_STATUS_SOFTLOCK.ToString() ||
                              row.Cells[8].Value.ToString() == Cyberarms.IntrusionDetection.Shared.Lock.LOCK_STATUS_HARDLOCK.ToString().ToString()))  {
                    long lockId;
                    if (long.TryParse(row.Cells[7].Value.ToString(), out lockId)) {
                        Lock l = Locks.GetLockById(lockId);
                        if (l != null) {
                            l.Status = Lock.LOCK_STATUS_UNLOCK_REQUESTED;
                            l.Save();
                        }
                        row.Cells[2].Value = LockStatusAdapter.GetLockStatusName((int)Lock.LOCK_STATUS_MANUAL);
                    }
                }
            }
        }

        public void UpdateLocksList(List<LockInfo> dbLocks) {
            bool changed = false;
            if (dataGridViewLocks.Rows.Count != dbLocks.Count) {
                changed = true;
            } else {
                for (int i = 0; i < dbLocks.Count; i++) {
                    DataGridViewRow row = dataGridViewLocks.Rows[i];
                    LockInfo dbLock = dbLocks[i];
                    if (row.Cells[7].Value == null || row.Cells[7].Value.ToString() != dbLock.Id.ToString()) {
                        changed = true;
                        break;
                    }
                    if (row.Cells[2].Value == null || row.Cells[2].Value.ToString() != dbLock.StatusName) {
                        changed = true;
                        break;
                    }
                    if (row.Cells[3].Value == null || row.Cells[3].Value.ToString() != dbLock.ClientIp) {
                        changed = true;
                        break;
                    }
                    if (row.Cells[8].Value == null || int.Parse(row.Cells[8].Value.ToString()) != dbLock.Status) {
                        changed = true;
                        break;
                    }
                    if (row.Cells[6].Value == null) {
                        changed = true;
                        break;
                    }
                    DateTime gridUnlockDate;
                    if (row.Cells[6].Value is DateTime) {
                        gridUnlockDate = (DateTime)row.Cells[6].Value;
                    } else if (!DateTime.TryParse(row.Cells[6].Value.ToString(), out gridUnlockDate)) {
                        changed = true;
                        break;
                    }
                    if (Math.Abs((gridUnlockDate - dbLock.UnlockDate).TotalSeconds) > 1) {
                        changed = true;
                        break;
                    }
                }
            }

            if (changed) {
                int firstVisibleRowIndex = dataGridViewLocks.FirstDisplayedScrollingRowIndex;
                dataGridViewLocks.Rows.Clear();
                foreach (LockInfo dbLock in dbLocks) {
                    int rowIndex = dataGridViewLocks.Rows.Add();
                    DataGridViewRow row = dataGridViewLocks.Rows[rowIndex];
                    row.Cells[0].Value = false;
                    (row.Cells[1] as DataGridViewImageCell).Value = global::Cyberarms.IntrusionDetection.Admin.Properties.Resources.logIcon_softLock;
                    row.Cells[2].Value = dbLock.StatusName;
                    row.Cells[3].Value = dbLock.ClientIp;
                    row.Cells[4].Value = dbLock.DisplayName;
                    row.Cells[5].Value = dbLock.LockDate;
                    row.Cells[6].Value = dbLock.UnlockDate;
                    row.Cells[7].Value = dbLock.Id.ToString();
                    row.Cells[8].Value = dbLock.Status;
                }
                if (firstVisibleRowIndex >= 0 && firstVisibleRowIndex < dataGridViewLocks.Rows.Count) {
                    try {
                        dataGridViewLocks.FirstDisplayedScrollingRowIndex = firstVisibleRowIndex;
                    } catch { }
                }
            }
        }
    }

    public class LockInfo {
        public int Id { get; set; }
        public string StatusName { get; set; }
        public string ClientIp { get; set; }
        public string DisplayName { get; set; }
        public DateTime LockDate { get; set; }
        public DateTime UnlockDate { get; set; }
        public int Status { get; set; }
    }
}
